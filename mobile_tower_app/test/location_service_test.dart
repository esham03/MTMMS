import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tower_app/services/location_service.dart';

void main() {
  group('LocationService Geographic Hierarchy Tests', () {
    test('Districts list contains North Goa and South Goa', () {
      final districts = LocationService.getDistricts();
      expect(districts, contains('North Goa'));
      expect(districts, contains('South Goa'));
    });

    test('Talukas filter accurately when North Goa is selected', () {
      final northTalukas = LocationService.getTalukas(district: 'North Goa');
      expect(northTalukas, contains('Bardez'));
      expect(northTalukas, contains('Tiswadi'));
      expect(northTalukas, contains('Bicholim'));
      expect(northTalukas, isNot(contains('Salcete')));
      expect(northTalukas, isNot(contains('Mormugao')));
    });

    test('Talukas filter accurately when South Goa is selected', () {
      final southTalukas = LocationService.getTalukas(district: 'South Goa');
      expect(southTalukas, contains('Salcete'));
      expect(southTalukas, contains('Mormugao'));
      expect(southTalukas, contains('Canacona'));
      expect(southTalukas, isNot(contains('Bardez')));
      expect(southTalukas, isNot(contains('Tiswadi')));
    });

    test('Constituencies filter accurately by District and Taluka', () {
      final tiswadiConsts = LocationService.getConstituencies(
        district: 'North Goa',
        taluka: 'Tiswadi',
      );
      expect(tiswadiConsts, contains('Panaji'));
      expect(tiswadiConsts, contains('Taleigao'));
      expect(tiswadiConsts, isNot(contains('Margao')));
      expect(tiswadiConsts, isNot(contains('Mapusa')));

      final salceteConsts = LocationService.getConstituencies(
        district: 'South Goa',
        taluka: 'Salcete',
      );
      expect(salceteConsts, contains('Margao'));
      expect(salceteConsts, contains('Fatorda'));
      expect(salceteConsts, isNot(contains('Panaji')));
    });

    test('Areas filter accurately by Constituency', () {
      final panajiAreas = LocationService.getAreas(
        district: 'North Goa',
        taluka: 'Tiswadi',
        constituency: 'Panaji',
      );
      expect(panajiAreas, contains('Panaji City'));
      expect(panajiAreas, contains('Miramar'));
      expect(panajiAreas, isNot(contains('Margao City')));
      expect(panajiAreas, isNot(contains('Calangute Beach')));

      final margaoAreas = LocationService.getAreas(
        district: 'South Goa',
        taluka: 'Salcete',
        constituency: 'Margao',
      );
      expect(margaoAreas, contains('Margao City'));
      expect(margaoAreas, contains('Aquem'));
      expect(margaoAreas, isNot(contains('Panaji City')));
    });

    test('Reverse district resolution for Taluka works', () {
      expect(LocationService.getDistrictForTaluka('Bardez'), equals('North Goa'));
      expect(LocationService.getDistrictForTaluka('Salcete'), equals('South Goa'));
      expect(LocationService.getDistrictForTaluka('Mormugao'), equals('South Goa'));
    });

    test('Reverse taluka resolution for Constituency works', () {
      expect(LocationService.getTalukaForConstituency('Panaji'), equals('Tiswadi'));
      expect(LocationService.getTalukaForConstituency('Margao'), equals('Salcete'));
      expect(LocationService.getTalukaForConstituency('Mapusa'), equals('Bardez'));
    });
  });
}
