import os
import sys
import django
from decimal import Decimal

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mtmms_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.towers.models import Tower, TowerRentRenewal
from apps.rent_payments.models import RentPayment
from apps.locations.models import Area
from apps.owners.models import Owner
from rest_framework.test import APIRequestFactory, force_authenticate
from apps.towers.views import TowerViewSet
from datetime import date, timedelta

User = get_user_model()

def run_tests():
    print("=" * 70)
    print("STARTING COMPREHENSIVE TOWER RENT ESCALATION ON RENEWAL TEST SUITE")
    print("=" * 70)
    
    # 1. Setup Admin User
    admin_user = User.objects.filter(role__iexact='admin').first() or User.objects.first()
    if not admin_user:
        admin_user = User.objects.create(
            name='Test Administrator',
            email='admin_test@goa.gov.in',
            password='password123',
            role='admin'
        )
    print(f"[OK] Authenticated Administrator: {admin_user.name} ({admin_user.email})")

    factory = APIRequestFactory()

    # Clean up prior test artifacts if present
    Tower.objects.filter(tower_unique_id='GA/TEST/ESC/001').delete()

    # 2. Test Case 1: Register New Tower with Escalation Configuration
    print("\n--- TEST CASE 1: Tower Registration with Escalation Configuration ---")
    first_area = Area.objects.first()
    first_owner = Owner.objects.first()

    test_tower = Tower.objects.create(
        tower_unique_id='GA/TEST/ESC/001',
        owner=first_owner,
        area=first_area,
        land_type='Government',
        height=35.0,
        width=3.0,
        frequency='1800 MHz / 5G NR',
        status='active',
        monthly_rent=round(200000.00 / 12, 2),
        yearly_rent=200000.00,
        rent_cycle_years=5,
        escalation_enabled=True,
        escalation_percentage=Decimal('10.00'),
        agreement_start_date=date(2021, 1, 1),
        agreement_end_date=date(2026, 1, 1),
        next_renewal_date=date(2026, 1, 1),
        last_revised_rent=Decimal('200000.00'),
        last_escalation_date=date(2021, 1, 1),
    )
    assert test_tower.escalation_enabled is True
    assert test_tower.escalation_percentage == Decimal('10.00')
    assert float(test_tower.yearly_rent) == 200000.00
    print(f"[PASSED] Tower {test_tower.tower_unique_id} registered. Yearly Rent: ₹{test_tower.yearly_rent}, Escalation: {test_tower.escalation_percentage}%, Cycle: {test_tower.rent_cycle_years} Yrs")

    # Seed an existing payment record to verify it is never overwritten
    legacy_payment = RentPayment.objects.create(
        tower=test_tower,
        payment_reference='RCP-TEST-2021-01',
        payment_date=date(2021, 1, 15),
        amount=200000.00,
        payment_method='RTGS',
        payment_status='paid',
        remarks='Initial 1st Year Payment'
    )
    print(f"[OK] Seeded Historical Payment Record: {legacy_payment.payment_reference} for ₹{legacy_payment.amount}")

    # 3. Test Case 2: Preview Renewal API (Compounding Calculation)
    print("\n--- TEST CASE 2: Renewal Preview API ---")
    view = TowerViewSet.as_view({'post': 'preview_renewal'})
    req = factory.post(f'/api/towers/{test_tower.id}/preview-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2026-01-01',
        'new_agreement_end_date': '2031-01-01'
    }, format='json')
    force_authenticate(req, user=admin_user)
    resp = view(req, pk=test_tower.id)
    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.data}"
    preview_data = resp.data['data']
    
    assert Decimal(str(preview_data['previous_annual_rent'])) == Decimal('200000.00')
    assert Decimal(str(preview_data['escalation_percentage'])) == Decimal('10.00')
    assert Decimal(str(preview_data['increase_amount'])) == Decimal('20000.00')
    assert Decimal(str(preview_data['proposed_new_annual_rent'])) == Decimal('220000.00')
    assert preview_data['renewal_cycle_years'] == 5
    print(f"[PASSED] Preview calculation exact: Previous ₹2,00,000 + 10% (₹20,000) = Proposed ₹2,20,000")

    # 4. Test Case 3: Confirmed Agreement Renewal with Escalation
    print("\n--- TEST CASE 3: Execute First Confirmed Agreement Renewal ---")
    confirm_view = TowerViewSet.as_view({'post': 'confirm_renewal'})
    req_confirm = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2026-01-01',
        'new_agreement_end_date': '2031-01-01',
        'is_manual_override': False
    }, format='json')
    force_authenticate(req_confirm, user=admin_user)
    resp_confirm = confirm_view(req_confirm, pk=test_tower.id)
    assert resp_confirm.status_code == 201, f"Expected 201, got {resp_confirm.status_code}: {resp_confirm.data}"
    
    test_tower.refresh_from_db()
    assert float(test_tower.yearly_rent) == 220000.00, f"Expected ₹220,000, got {test_tower.yearly_rent}"
    assert Decimal(str(test_tower.last_revised_rent)) == Decimal('220000.00')
    assert str(test_tower.agreement_start_date) == '2026-01-01'
    assert str(test_tower.agreement_end_date) == '2031-01-01'
    assert str(test_tower.next_renewal_date) == '2031-01-01'

    # Check renewal audit record
    renewal_1 = TowerRentRenewal.objects.filter(tower=test_tower).latest('created_at')
    assert Decimal(str(renewal_1.previous_annual_rent)) == Decimal('200000.00')
    assert Decimal(str(renewal_1.escalation_percentage)) == Decimal('10.00')
    assert Decimal(str(renewal_1.increase_amount)) == Decimal('20000.00')
    assert Decimal(str(renewal_1.new_annual_rent)) == Decimal('220000.00')
    assert renewal_1.is_escalation_applied is True
    assert renewal_1.is_manual_override is False
    assert renewal_1.approved_by == admin_user
    print(f"[PASSED] Renewal 1 Confirmed! Ref: {renewal_1.reference_number}, Revised Rent: ₹{test_tower.yearly_rent}, Next Renewal: {test_tower.next_renewal_date}")

    # 5. Test Case 4: Subsequent Renewal (Compounding: ₹2,20,000 + 10% = ₹2,42,000)
    print("\n--- TEST CASE 4: Subsequent Renewal Compounding Verification ---")
    req_confirm_2 = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2031-01-01',
        'new_agreement_end_date': '2036-01-01',
        'is_manual_override': False
    }, format='json')
    force_authenticate(req_confirm_2, user=admin_user)
    resp_confirm_2 = confirm_view(req_confirm_2, pk=test_tower.id)
    assert resp_confirm_2.status_code == 201, f"Expected 201, got {resp_confirm_2.status_code}: {resp_confirm_2.data}"

    test_tower.refresh_from_db()
    # Expected: 220000 + (220000 * 10 / 100) = 242000.00 (NOT based on original 200000!)
    assert float(test_tower.yearly_rent) == 242000.00, f"Compounding failed! Expected 242000.00, got {test_tower.yearly_rent}"
    
    renewal_2 = TowerRentRenewal.objects.filter(tower=test_tower).latest('created_at')
    assert Decimal(str(renewal_2.previous_annual_rent)) == Decimal('220000.00')
    assert Decimal(str(renewal_2.increase_amount)) == Decimal('22000.00')
    assert Decimal(str(renewal_2.new_annual_rent)) == Decimal('242000.00')
    print(f"[PASSED] Compounding verified: ₹2,20,000 -> ₹2,42,000 (+₹22,000 / 10%) on subsequent renewal!")

    # 6. Test Case 5: Renewal with Escalation Disabled
    print("\n--- TEST CASE 5: Renewal with Escalation Disabled ---")
    test_tower.escalation_enabled = False
    test_tower.save()

    req_confirm_disabled = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2036-01-01',
        'new_agreement_end_date': '2041-01-01',
        'is_manual_override': False
    }, format='json')
    force_authenticate(req_confirm_disabled, user=admin_user)
    resp_confirm_disabled = confirm_view(req_confirm_disabled, pk=test_tower.id)
    assert resp_confirm_disabled.status_code == 201

    test_tower.refresh_from_db()
    # Rent must remain unchanged at ₹242,000
    assert float(test_tower.yearly_rent) == 242000.00
    renewal_3 = TowerRentRenewal.objects.filter(tower=test_tower).latest('created_at')
    assert renewal_3.is_escalation_applied is False
    assert Decimal(str(renewal_3.increase_amount)) == Decimal('0.00')
    assert Decimal(str(renewal_3.new_annual_rent)) == Decimal('242000.00')
    print(f"[PASSED] Disabled escalation verified: Rent remained constant at ₹{test_tower.yearly_rent}")

    # 7. Test Case 6: Administrator Manual Override with Mandatory Reason
    print("\n--- TEST CASE 6: Administrator Manual Rent Override ---")
    # First test missing justification rejection
    req_override_invalid = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2041-01-01',
        'new_agreement_end_date': '2046-01-01',
        'is_manual_override': True,
        'manual_new_rent': 260000.00,
        'override_reason': '' # empty reason!
    }, format='json')
    force_authenticate(req_override_invalid, user=admin_user)
    resp_override_invalid = confirm_view(req_override_invalid, pk=test_tower.id)
    assert resp_override_invalid.status_code == 400, "Should reject manual override with empty reason"
    print("[PASSED] Correctly rejected manual override when mandatory reason was omitted.")

    # Now valid override
    req_override_valid = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2041-01-01',
        'new_agreement_end_date': '2046-01-01',
        'is_manual_override': True,
        'manual_new_rent': 260000.00,
        'override_reason': 'Special administrative committee revision order #DOIT-2041/09'
    }, format='json')
    force_authenticate(req_override_valid, user=admin_user)
    resp_override_valid = confirm_view(req_override_valid, pk=test_tower.id)
    assert resp_override_valid.status_code == 201

    test_tower.refresh_from_db()
    assert float(test_tower.yearly_rent) == 260000.00
    renewal_4 = TowerRentRenewal.objects.filter(tower=test_tower).latest('created_at')
    assert renewal_4.is_manual_override is True
    assert Decimal(str(renewal_4.new_annual_rent)) == Decimal('260000.00')
    assert 'DOIT-2041/09' in renewal_4.override_reason
    print(f"[PASSED] Manual override applied: Rent set to ₹{test_tower.yearly_rent}. Reason logged in audit trail: '{renewal_4.override_reason}'")

    # 8. Test Case 7: Duplicate Renewal Submission Prevention
    print("\n--- TEST CASE 7: Duplicate Submission Prevention ---")
    req_duplicate = factory.post(f'/api/towers/{test_tower.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2041-01-01',
        'new_agreement_end_date': '2046-01-01',
        'is_manual_override': False
    }, format='json')
    force_authenticate(req_duplicate, user=admin_user)
    resp_duplicate = confirm_view(req_duplicate, pk=test_tower.id)
    assert resp_duplicate.status_code == 400, "Should reject duplicate renewal for existing active/overlapping agreement tenure"
    print(f"[PASSED] Duplicate renewal prevented with error: {resp_duplicate.data['error']}")

    # 9. Test Case 8: Preservation of Payment History and Integrity
    print("\n--- TEST CASE 8: Payment & Historical Financial Ledger Preservation ---")
    legacy_payment.refresh_from_db()
    assert float(legacy_payment.amount) == 200000.00
    assert legacy_payment.payment_status == 'paid'
    print(f"[PASSED] Original payment record untouched and fully preserved: {legacy_payment.payment_reference} = ₹{legacy_payment.amount}")

    # Verify complete renewal ledger for this tower
    renewals = TowerRentRenewal.objects.filter(tower=test_tower).order_by('created_at')
    assert renewals.count() == 4
    print(f"[PASSED] Tower renewal audit ledger contains {renewals.count()} sequential immutable entries:")
    for idx, r in enumerate(renewals, 1):
        print(f"  Entry {idx}: {r.reference_number} | Old: ₹{r.previous_annual_rent} -> New: ₹{r.new_annual_rent} | Inc: +₹{r.increase_amount} ({r.escalation_percentage}%) | Override: {r.is_manual_override} | Approved By: {r.approved_by.name or r.approved_by.email}")

    # Clean up test tower
    test_tower.delete()
    print("\n[CLEANUP] Initial test tower cleaned up successfully.")

    # 10. Test Case 9: Direct Escalation Rate Adjustment Endpoint
    print("\n--- TEST CASE 9: Direct Escalation Rate Adjustment Endpoint ---")
    tower_adj = Tower.objects.create(
        tower_unique_id='GA/TEST/ESC/002',
        owner=first_owner,
        area=first_area,
        land_type='Government',
        height=30.0,
        width=3.0,
        status='active',
        monthly_rent=round(100000.00 / 12, 2),
        yearly_rent=100000.00,
        rent_cycle_years=5,
        escalation_enabled=True,
        escalation_percentage=Decimal('10.00'),
        agreement_start_date=date(2022, 1, 1),
        agreement_end_date=date(2027, 1, 1),
        next_renewal_date=date(2027, 1, 1),
    )

    update_esc_view = TowerViewSet.as_view({'post': 'update_escalation'})
    
    # Negative rate rejection
    req_neg = factory.post(f'/api/towers/{tower_adj.id}/update-escalation/', {
        'escalation_percentage': -5.0,
        'escalation_enabled': True,
    }, format='json')
    force_authenticate(req_neg, user=admin_user)
    resp_neg = update_esc_view(req_neg, pk=tower_adj.id)
    assert resp_neg.status_code == 400, "Should reject negative escalation percentage"
    print("[PASSED] Rejection of negative escalation rate verified (400 Bad Request).")

    # Rate > 100 rejection
    req_over = factory.post(f'/api/towers/{tower_adj.id}/update-escalation/', {
        'escalation_percentage': 150.0,
        'escalation_enabled': True,
    }, format='json')
    force_authenticate(req_over, user=admin_user)
    resp_over = update_esc_view(req_over, pk=tower_adj.id)
    assert resp_over.status_code == 400, "Should reject escalation percentage > 100"
    print("[PASSED] Rejection of escalation rate > 100% verified (400 Bad Request).")

    # Valid rate adjustment from 10% to 12.5%
    req_adj = factory.post(f'/api/towers/{tower_adj.id}/update-escalation/', {
        'escalation_percentage': 12.5,
        'escalation_enabled': True,
    }, format='json')
    force_authenticate(req_adj, user=admin_user)
    resp_adj = update_esc_view(req_adj, pk=tower_adj.id)
    assert resp_adj.status_code == 200, f"Expected 200, got {resp_adj.status_code}: {resp_adj.data}"
    
    tower_adj.refresh_from_db()
    assert tower_adj.escalation_percentage == Decimal('12.50')
    assert tower_adj.escalation_enabled is True
    print(f"[PASSED] Directly adjusted escalation rate to {tower_adj.escalation_percentage}% successfully.")

    # 11. Test Case 10: Manual Rate Adjustment During Renewal Confirmation
    print("\n--- TEST CASE 10: Manual Rate Adjustment During Renewal Confirmation ---")
    # Base rent ₹1,00,000, adjust rate to 15% during renewal confirmation
    req_adj_renew = factory.post(f'/api/towers/{tower_adj.id}/confirm-renewal/', {
        'renewal_cycle_years': 5,
        'new_agreement_start_date': '2027-01-01',
        'new_agreement_end_date': '2032-01-01',
        'escalation_enabled': True,
        'escalation_percentage': 15.0,  # Adjusted from 12.5% to 15% during renewal
        'is_manual_override': False,
    }, format='json')
    force_authenticate(req_adj_renew, user=admin_user)
    resp_adj_renew = confirm_view(req_adj_renew, pk=tower_adj.id)
    assert resp_adj_renew.status_code == 201, f"Expected 201, got {resp_adj_renew.status_code}: {resp_adj_renew.data}"

    tower_adj.refresh_from_db()
    # Expected new rent: 100,000 + (100,000 * 15 / 100) = 115,000.00
    assert float(tower_adj.yearly_rent) == 115000.00, f"Expected ₹115,000, got {tower_adj.yearly_rent}"
    assert tower_adj.escalation_percentage == Decimal('15.00')

    renewal_adj = TowerRentRenewal.objects.filter(tower=tower_adj).latest('created_at')
    assert Decimal(str(renewal_adj.previous_annual_rent)) == Decimal('100000.00')
    assert Decimal(str(renewal_adj.escalation_percentage)) == Decimal('15.00')
    assert Decimal(str(renewal_adj.increase_amount)) == Decimal('15000.00')
    assert Decimal(str(renewal_adj.new_annual_rent)) == Decimal('115000.00')
    print(f"[PASSED] Adjusted rate renewal applied: Base ₹1,00,000 + 15% (₹15,000) = Revised ₹1,15,000. Tower rate updated to 15%.")

    # Clean up second test tower
    tower_adj.delete()
    print("\n[CLEANUP] Adjusted rate test tower cleaned up successfully.")

    print("\n" + "=" * 70)
    print("ALL 10 BUSINESS LOGIC AND VERIFICATION SUITES PASSED WITH 100% SUCCESS!")
    print("=" * 70)

if __name__ == '__main__':
    run_tests()
