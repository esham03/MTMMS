import React, { useState, useEffect, useRef, useMemo } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  MapPin,
  Radio,
  Building2,
  Landmark,
  IndianRupee,
  Layers,
  Filter,
  Search,
  RefreshCw,
  ExternalLink,
  AlertCircle,
  CheckCircle2,
  Clock,
  Compass,
} from "lucide-react";
import towerApi from "../api/towerApi";
import Loading from "../components/Loading";
import { useAuth } from "../context/AuthContext";

// High-Precision Real-World Geographic Coordinates for Goa Talukas, Areas & Landmarks
export const GOA_EXACT_LOCATION_COORDS = {
  // Specific Landmark Premise Locations
  "ponda police station": [15.40182, 74.01525],
  "inside premise of ponda police station": [15.40182, 74.01525],
  "mapusa market": [15.5925, 73.8120],
  "plot 42, mapusa market road, bardez": [15.5925, 73.8120],
  "patto plaza": [15.4944, 73.8375],
  "dabolim airport": [15.3808, 73.8313],
  "mormugao port": [15.4124, 73.7997],
  "mopa airport": [15.7533, 73.8647],

  // Talukas & Major Municipal Centers
  bardez: [15.5937, 73.8142],
  mapusa: [15.5937, 73.8142],
  "mapusa town": [15.5937, 73.8142],
  tiswadi: [15.4909, 73.8278],
  panaji: [15.4909, 73.8278],
  "panaji city": [15.4909, 73.8278],
  salcete: [15.2736, 73.9582],
  margao: [15.2736, 73.9582],
  "margao city": [15.2736, 73.9582],
  mormugao: [15.3982, 73.8113],
  vasco: [15.3982, 73.8113],
  "vasco da gama": [15.3982, 73.8113],
  ponda: [15.4018, 74.0152],
  "ponda city": [15.4018, 74.0152],
  bicholim: [15.5947, 73.9536],
  "bicholim town": [15.5947, 73.9536],
  pernem: [15.7176, 73.7964],
  "pernem town": [15.7176, 73.7964],
  sattari: [15.5312, 74.1165],
  valpoi: [15.5312, 74.1165],
  "valpoi town": [15.5312, 74.1165],
  quepem: [15.2185, 74.0734],
  "quepem town": [15.2185, 74.0734],
  sanguem: [15.2307, 74.1569],
  "sanguem town": [15.2307, 74.1569],
  canacona: [14.9998, 74.0537],
  "canacona (chaudi)": [14.9998, 74.0537],
  dharbandora: [15.3855, 74.1722],
  "dharbandora town": [15.3855, 74.1722],

  // North Goa - Bardez Areas
  calangute: [15.5439, 73.7554],
  candolim: [15.5178, 73.7667],
  porvorim: [15.5348, 73.8294],
  anjuna: [15.5843, 73.7438],
  baga: [15.5553, 73.7517],
  aldona: [15.5898, 73.8732],
  siolim: [15.6268, 73.7686],
  saligao: [15.5517, 73.7845],
  arpora: [15.5683, 73.7645],
  nerul: [15.5112, 73.7847],
  "penha de franca": [15.5218, 73.8344],
  pilerne: [15.5322, 73.7997],
  moira: [15.6025, 73.8504],
  guirim: [15.5701, 73.8182],

  // North Goa - Tiswadi Areas
  miramar: [15.4833, 73.8083],
  caranzalem: [15.4744, 73.8131],
  "dona paula": [15.4578, 73.8056],
  bambolim: [15.4522, 73.8533],
  taleigao: [15.4678, 73.8244],
  "santa cruz": [15.4733, 73.8444],
  ribandar: [15.5033, 73.8644],
  "old goa": [15.5009, 73.9116],
  corlim: [15.4983, 73.9317],
  pilar: [15.4417, 73.8967],

  // North Goa - Pernem Areas
  mandrem: [15.6706, 73.7175],
  morjim: [15.6247, 73.7317],
  arambol: [15.6853, 73.7042],
  ashvem: [15.6583, 73.7194],
  "mopa airport area": [15.7533, 73.8647],
  dhargal: [15.6983, 73.8317],
  tuem: [15.6817, 73.7817],

  // North Goa - Bicholim Areas
  sanquelim: [15.5617, 74.0117],
  mayem: [15.5783, 73.9533],
  mulgao: [15.6083, 73.9317],
  bordem: [15.5983, 73.9617],
  pale: [15.5183, 74.0517],

  // North Goa - Sattari Areas
  honda: [15.5417, 74.0617],
  pissurlem: [15.5217, 74.0917],
  nagargao: [15.5117, 74.1317],
  "thane sattari": [15.5517, 74.1517],
  birondem: [15.5317, 74.1017],

  // South Goa - Ponda Areas
  farmagudi: [15.4217, 73.9983],
  bandora: [15.4117, 73.9883],
  curti: [15.4083, 74.0217],
  "kundaim industrial estate": [15.4417, 73.9617],
  marcaim: [15.4183, 73.9417],
  shiroda: [15.3417, 74.0617],
  borim: [15.3617, 74.0317],
  priol: [15.4483, 73.9817],

  // South Goa - Salcete Areas
  fatorda: [15.2917, 73.9617],
  benaulim: [15.2517, 73.9217],
  nuvem: [15.3117, 73.9417],
  navelim: [15.2617, 73.9717],
  curtorim: [15.2817, 74.0117],
  majorda: [15.3183, 73.9183],
  betalbatim: [15.2983, 73.9183],
  varca: [15.2217, 73.9217],
  cavelossim: [15.1783, 73.9417],
  raia: [15.3117, 73.9917],
  loutolim: [15.3317, 73.9817],
  colva: [15.2800, 73.9200],

  // South Goa - Mormugao Areas
  "dabolim (airport)": [15.3808, 73.8313],
  cortalim: [15.3983, 73.9117],
  "sancoale industrial estate": [15.3817, 73.8817],
  chicalim: [15.3917, 73.8417],
  bogmalo: [15.3517, 73.8317],
  velsao: [15.3483, 73.8817],
  "mormugao port harbour": [15.4124, 73.7997],

  // South Goa - Quepem Areas
  curchorem: [15.2583, 74.1117],
  sanvordem: [15.2617, 74.1217],
  tilamol: [15.2317, 74.0917],
  balli: [15.1717, 74.0317],
  morpirla: [15.1417, 74.0917],

  // South Goa - Sanguem Areas
  uguem: [15.2117, 74.1617],
  netravali: [15.0917, 74.2117],
  rivona: [15.1917, 74.1117],
  curdi: [15.1617, 74.1817],
  bhati: [15.1417, 74.1917],

  // South Goa - Canacona Areas
  palolem: [15.0100, 74.0233],
  agonda: [15.0450, 73.9883],
  patnem: [15.0017, 74.0317],
  poinguinim: [14.9617, 74.0817],
  loliem: [14.9317, 74.1117],
  gaondongrem: [15.0217, 74.1117],

  // South Goa - Dharbandora Areas
  mollem: [15.3817, 74.2217],
  colem: [15.3517, 74.2417],
  sacorda: [15.4317, 74.1617],
  "sanjeevani sugar factory area": [15.3917, 74.1417],
};

export const MapView = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { theme } = useAuth();
  const [towers, setTowers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [districtFilter, setDistrictFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [landFilter, setLandFilter] = useState("all");
  const [companyFilter, setCompanyFilter] = useState(
    searchParams.get("company") || searchParams.get("operator") || (searchParams.get("operator_id") ? `op_id:${searchParams.get("operator_id")}` : "all")
  );
  const [searchQuery, setSearchQuery] = useState(
    searchParams.get("search") || searchParams.get("q") || ""
  );
  const [selectedTower, setSelectedTower] = useState(null);
  const [availableOperators, setAvailableOperators] = useState([]);

  useEffect(() => {
    const q = searchParams.get("search") || searchParams.get("q");
    if (q !== null && q !== undefined) {
      setSearchQuery(q);
    }
    const comp = searchParams.get("company") || searchParams.get("operator");
    if (comp) {
      setCompanyFilter(comp);
    } else if (searchParams.get("operator_id")) {
      setCompanyFilter(`op_id:${searchParams.get("operator_id")}`);
    }
  }, [searchParams]);

  useEffect(() => {
    window.__mtmmsNavigateToTower = (towerId) => {
      navigate(`/towers/${towerId}`);
    };
    return () => {
      delete window.__mtmmsNavigateToTower;
    };
  }, [navigate]);

  const mapContainerRef = useRef(null);
  const [mapInstance, setMapInstance] = useState(null);
  const mapInstanceRef = useRef(null);
  const markersLayerRef = useRef(null);

  // Fetch all towers and operators
  const loadTowers = async () => {
    setIsLoading(true);
    try {
      const [towersData, opsData] = await Promise.all([
        towerApi.getTowers().catch(() => []),
        towerApi.getOperators({ all: true }).catch(() => []),
      ]);
      setTowers(Array.isArray(towersData) ? towersData : []);
      setAvailableOperators(Array.isArray(opsData) ? opsData : []);
    } catch (e) {
      console.error("Failed to load map towers", e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadTowers();
  }, []);

  // Compute status for each tower
  const processedTowers = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const in30 = new Date(today);
    in30.setDate(in30.getDate() + 30);

    return towers.map((t, idx) => {
      let status = "paid";
      if (t.rent_due_date) {
        const due = new Date(t.rent_due_date);
        if (!isNaN(due.getTime())) {
          due.setHours(0, 0, 0, 0);
          if (due < today) status = "overdue";
          else if (due <= in30) status = "due_soon";
        }
      }

      // 1. High-Precision Coordinate Resolution: Prioritize exact GPS coordinates
      let lat = parseFloat(t.latitude);
      let lng = parseFloat(t.longitude);
      let isExactGps = false;

      // Validate if lat/lng is explicitly stored and falls within Goa boundaries
      if (
        !isNaN(lat) &&
        !isNaN(lng) &&
        lat >= 14.7 &&
        lat <= 15.9 &&
        lng >= 73.6 &&
        lng <= 74.5
      ) {
        isExactGps = true;
      } else {
        // 2. Intelligent Address & Area Exact Matching across Goa
        const addr = String(t.address || "").toLowerCase().trim();
        const areaName = String(t.area?.name || t.area_name || "").toLowerCase().trim();
        const talukaName = String(t.taluka?.name || t.taluka_name || t.area?.taluka?.name || "").toLowerCase().trim();

        let matched = null;

        // Check if any specific landmark or street in the database matches address
        for (const [key, coords] of Object.entries(GOA_EXACT_LOCATION_COORDS)) {
          if (key.length > 5 && addr.includes(key)) {
            matched = coords;
            break;
          }
        }

        // Match against exact area name
        if (!matched && areaName && GOA_EXACT_LOCATION_COORDS[areaName]) {
          matched = GOA_EXACT_LOCATION_COORDS[areaName];
        }

        // Match against exact taluka name
        if (!matched && talukaName && GOA_EXACT_LOCATION_COORDS[talukaName]) {
          matched = GOA_EXACT_LOCATION_COORDS[talukaName];
        }

        if (matched) {
          lat = matched[0];
          lng = matched[1];
        } else {
          // Standard Goa Central Reference (Ponda / Old Goa junction)
          lat = 15.35;
          lng = 73.95;
        }
      }

      return {
        ...t,
        _status: status,
        _lat: lat,
        _lng: lng,
        _isExactGps: isExactGps,
      };
    });
  }, [towers]);

  // Dynamic list of telecom operators and infrastructure companies
  const companyOptions = useMemo(() => {
    const map = new Map();
    // From loaded operators endpoint
    availableOperators.forEach((op) => {
      if (op && (op.name || op.short_name)) {
        const label = (op.short_name || op.name).trim();
        map.set(label.toLowerCase(), label);
      }
    });
    // From towers' attached operators and owners
    towers.forEach((t) => {
      if (Array.isArray(t.operators)) {
        t.operators.forEach((op) => {
          if (op && (op.name || op.short_name)) {
            const label = (op.short_name || op.name).trim();
            map.set(label.toLowerCase(), label);
          }
        });
      }
      if (t.operator && typeof t.operator === "string" && t.operator !== "None") {
        map.set(t.operator.toLowerCase().trim(), t.operator.trim());
      }
      if (t.owner?.name) {
        const ow = t.owner.name.trim();
        const low = ow.toLowerCase();
        if (
          low.includes("infrastructure") ||
          low.includes("telecom") ||
          low.includes("towers") ||
          low.includes("summit") ||
          low.includes("indus") ||
          low.includes("airtel") ||
          low.includes("jio")
        ) {
          map.set(low, ow);
        }
      }
    });
    return Array.from(map.values()).sort();
  }, [availableOperators, towers]);

  // Filtered towers with deep company and operator search
  const filteredTowers = useMemo(() => {
    return processedTowers.filter((t) => {
      if (districtFilter !== "all") {
        const distName = String(
          t.district?.name || t.district_name || t.area?.taluka?.constituency?.district?.name || ""
        ).toLowerCase();
        if (!distName.includes(districtFilter)) return false;
      }

      if (statusFilter !== "all" && t._status !== statusFilter) {
        return false;
      }

      if (landFilter !== "all") {
        const lt = String(t.land_type || "").toLowerCase();
        if (lt !== landFilter) return false;
      }

      // Company / Operator Dropdown filter
      if (companyFilter !== "all") {
        const target = companyFilter.toLowerCase();
        const matchesOp = Array.isArray(t.operators) && t.operators.some((op) => {
          const name = String(op.name || "").toLowerCase();
          const short = String(op.short_name || "").toLowerCase();
          return name.includes(target) || short.includes(target);
        });
        const matchesSingleOp = String(t.operator || t.company || "").toLowerCase().includes(target);
        const matchesOwner = String(t.owner?.name || "").toLowerCase().includes(target);

        if (!matchesOp && !matchesSingleOp && !matchesOwner) {
          return false;
        }
      }

      // Search query (Company, Operator, Tower ID, Area, Taluka, District, Address, Owner)
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const idMatch = String(t.tower_unique_id || t.id || "").toLowerCase().includes(q);
        const areaMatch = String(t.area?.name || t.area_name || "").toLowerCase().includes(q);
        const talukaMatch = String(t.taluka?.name || t.taluka_name || t.area?.taluka?.name || "").toLowerCase().includes(q);
        const districtMatch = String(t.district?.name || t.district_name || t.area?.taluka?.constituency?.district?.name || "").toLowerCase().includes(q);
        const addressMatch = String(t.address || "").toLowerCase().includes(q);

        // Match Owner / Infrastructure Provider Company (e.g. Summit Digital Infrastructure, Indus Towers)
        const ownerMatch = String(t.owner?.name || t.owner?.company_name || "").toLowerCase().includes(q);

        // Match Telecom Operator Companies (e.g. Airtel, Reliance Jio, Vi, Vodafone, BSNL)
        const operatorMatch = Array.isArray(t.operators) && t.operators.some((op) => {
          const name = String(op.name || "").toLowerCase();
          const short = String(op.short_name || "").toLowerCase();
          return name.includes(q) || short.includes(q);
        });

        // Single operator/company field fallback
        const singleOpMatch = String(t.operator || t.company || t.operator_name || "").toLowerCase().includes(q);

        if (
          !idMatch &&
          !areaMatch &&
          !talukaMatch &&
          !districtMatch &&
          !addressMatch &&
          !ownerMatch &&
          !operatorMatch &&
          !singleOpMatch
        ) {
          return false;
        }
      }

      return true;
    });
  }, [processedTowers, districtFilter, statusFilter, landFilter, companyFilter, searchQuery]);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Prevent double initialization on the same DOM element
    if (mapContainerRef.current._leaflet_id) {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    }

    // Goa Center: [15.2993, 74.0500]
    const map = L.map(mapContainerRef.current, {
      center: [15.32, 74.04],
      zoom: 10,
      zoomControl: true,
      maxBounds: [
        [14.6, 73.4],
        [16.0, 74.6],
      ],
      minZoom: 9,
    });

    // High-performance Basemaps (100% Free, Zero API Keys, Zero Watermarks)
    const osmLayer = L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">OpenStreetMap</a> contributors',
      maxZoom: 19,
      subdomains: ["a", "b", "c"],
    });

    const satelliteLayer = L.tileLayer(
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
      {
        attribution: 'Tiles &copy; Esri &mdash; Maxar, Earthstar Geographics',
        maxZoom: 19,
      }
    );

    const streetLayer = L.tileLayer(
      "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}",
      {
        attribution: 'Tiles &copy; Esri &mdash; Street Map',
        maxZoom: 19,
      }
    );

    // Default active layer: OpenStreetMap Standard (Clean, zero watermark, completely free)
    osmLayer.addTo(map);

    const baseMaps = {
      "OpenStreetMap (Standard)": osmLayer,
      "Satellite View (Esri)": satelliteLayer,
      "Street Map (Esri)": streetLayer,
    };

    L.control.layers(baseMaps, null, { position: "topright", collapsed: true }).addTo(map);

    const markersLayer = L.layerGroup().addTo(map);
    markersLayerRef.current = markersLayer;
    mapInstanceRef.current = map;
    setMapInstance(map);

    // Intercept popup buttons to ensure SPA navigation inside Electron and Web
    map.on("popupopen", (e) => {
      const container = e.popup?.getElement();
      if (container) {
        const btn = container.querySelector(".leaflet-tower-details-btn");
        if (btn) {
          btn.onclick = (evt) => {
            evt.preventDefault();
            evt.stopPropagation();
            const id = btn.getAttribute("data-tower-id");
            if (id) {
              navigate(`/towers/${id}`);
            }
          };
        }
      }
    });

    // Call invalidateSize after paint to ensure complete canvas coverage
    const t1 = setTimeout(() => map.invalidateSize(), 150);
    const t2 = setTimeout(() => map.invalidateSize(), 500);

    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      map.remove();
      mapInstanceRef.current = null;
      markersLayerRef.current = null;
      setMapInstance(null);
    };
  }, [theme]);

  // Update Markers when filteredTowers or mapInstance change
  useEffect(() => {
    const map = mapInstance;
    const markersLayer = markersLayerRef.current;
    if (!map || !markersLayer) return;

    markersLayer.clearLayers();

    filteredTowers.forEach((t) => {
      const color =
        t._status === "overdue"
          ? "#ef4444"
          : t._status === "due_soon"
          ? "#f59e0b"
          : "#10b981";

      const iconHtml = `
        <div style="
          width: 32px;
          height: 32px;
          border-radius: 50%;
          background: ${color}20;
          border: 2px solid ${color};
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 0 10px ${color}80;
          cursor: pointer;
        ">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"/>
            <path d="M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"/>
            <circle cx="12" cy="12" r="2"/>
            <path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5"/>
            <path d="M19.1 4.9C23 8.8 23 15.1 19.1 19"/>
          </svg>
        </div>
      `;

      const customIcon = L.divIcon({
        html: iconHtml,
        className: "custom-leaflet-marker",
        iconSize: [32, 32],
        iconAnchor: [16, 16],
      });

      const marker = L.marker([t._lat, t._lng], { icon: customIcon });

      const yearlyRent =
        parseFloat(t.yearly_rent) ||
        (parseFloat(t.monthly_rent) || 0) * 12;

      const operatorNames = Array.isArray(t.operators) && t.operators.length > 0
        ? t.operators.map(op => op.short_name || op.name).join(", ")
        : (t.operator || "None Assigned");

      const heightVal = parseFloat(t.height || t.height_meters || t.height_m) || 0;
      const widthVal = parseFloat(t.width || t.width_meters || t.base_width || t.width_m) || 0;
      const heightStr = heightVal > 0 ? `${heightVal}m (${Math.round(heightVal * 3.28084)} ft)` : "—";
      const spaceStr = widthVal > 0 ? `${widthVal}m (${Math.round(widthVal * 3.28084)} ft)` : "—";

      const popupContent = `
        <div style="font-family: 'Inter', sans-serif; min-width: 240px; color: #0f172a; padding: 4px;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px;">
            <strong style="font-size: 13px; color: #1e293b;">${t.tower_unique_id || `TWR-${t.id}`}</strong>
            <span style="
              font-size: 9px;
              font-weight: 800;
              padding: 1px 6px;
              border-radius: 12px;
              text-transform: uppercase;
              color: ${color};
              background: ${color}15;
              border: 1px solid ${color}40;
            ">
              ${t._status.replace("_", " ")}
            </span>
          </div>
          <div style="font-size: 11px; color: #64748b; margin-bottom: 6px;">
            ${t.area?.name || t.area_name || "Goa"} · ${t.area?.taluka?.name || t.taluka?.name || "Taluka"}
          </div>
          <div style="font-size: 11px; border-top: 1px solid #e2e8f0; padding-top: 6px; margin-bottom: 8px;">
            <div style="margin-bottom: 3px;"><strong>Telecom Company:</strong> <span style="color: #2563eb; font-weight: 600;">${operatorNames}</span></div>
            <div style="margin-bottom: 3px;"><strong>Owner / Infra:</strong> ${t.owner?.name || (String(t.land_type).toLowerCase() === "government" ? "Govt. of Goa" : "Private")}</div>
            <div style="margin-bottom: 3px;"><strong>Height:</strong> ${heightStr}</div>
            <div style="margin-bottom: 3px;"><strong>Base / Space:</strong> ${spaceStr}</div>
            <div style="margin-bottom: 3px;"><strong>Annual Rent:</strong> ₹${yearlyRent.toLocaleString()}</div>
            <div style="margin-top: 5px; padding-top: 4px; border-top: 1px dashed #cbd5e1; display: flex; align-items: center; justify-content: space-between;">
              <span style="font-size: 10px; color: #64748b; font-weight: 600;">GPS Location:</span>
              <span style="font-size: 10px; font-weight: 700; color: #ff5100; font-family: monospace;">
                ${t._lat.toFixed(5)}°N, ${t._lng.toFixed(5)}°E
              </span>
            </div>
            ${t.address ? `<div style="font-size: 10px; color: #334155; margin-top: 3px; line-height: 1.3;"><strong>Site:</strong> ${t.address}</div>` : ""}
          </div>
          <button
            type="button"
            class="leaflet-tower-details-btn"
            data-tower-id="${t.id}"
            onclick="event.preventDefault(); event.stopPropagation(); window.__mtmmsNavigateToTower && window.__mtmmsNavigateToTower('${t.id}')"
            style="
              width: 100%;
              display: block;
              text-align: center;
              background: linear-gradient(135deg, #ff5100 0%, #ff7700 100%);
              color: #ffffff;
              font-size: 11px;
              font-weight: 700;
              padding: 7px 10px;
              border-radius: 6px;
              border: none;
              cursor: pointer;
              box-shadow: 0 2px 8px rgba(255, 81, 0, 0.35);
              transition: all 0.2s ease;
            "
          >
            View Full Tower Details →
          </button>
        </div>
      `;

      marker.bindPopup(popupContent, { maxWidth: 290 });
      marker.on("click", () => setSelectedTower(t));
      markersLayer.addLayer(marker);
    });
  }, [mapInstance, filteredTowers]);

  // Auto-pan / fit bounds when searching or filtering by company
  useEffect(() => {
    const map = mapInstance;
    if (!map || filteredTowers.length === 0) return;
    if (!searchQuery.trim() && companyFilter === "all" && districtFilter === "all") return;

    if (filteredTowers.length === 1) {
      map.flyTo([filteredTowers[0]._lat, filteredTowers[0]._lng], 16, { duration: 0.8 });
    } else if (filteredTowers.length > 1) {
      const bounds = L.latLngBounds(filteredTowers.map((t) => [t._lat, t._lng]));
      map.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 });
    }
  }, [mapInstance, filteredTowers, searchQuery, companyFilter, districtFilter]);

  const handleFlyToTower = (t) => {
    const map = mapInstance;
    if (!map) return;
    map.flyTo([t._lat, t._lng], 16, { duration: 1.0 });
    setSelectedTower(t);
  };

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h1>Goa GIS Tower Infrastructure Map</h1>
          <p>
            Spatial distribution of registered telecommunication towers across
            North &amp; South Goa
          </p>
        </div>

        <div className="page-actions">
          <button className="btn btn-secondary btn-sm" onClick={loadTowers}>
            <RefreshCw size={14} />
            <span>Sync Live Pins</span>
          </button>
          <button
            className="btn btn-primary btn-sm"
            onClick={() => navigate("/towers?action=create")}
          >
            <Radio size={14} />
            <span>Register Tower</span>
          </button>
        </div>
      </div>

      {/* Map Control Bar & Filters */}
      <div
        className="card"
        style={{
          marginBottom: 16,
          padding: "12px 16px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: 12,
        }}
      >
        {/* Left: Filters */}
        <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: "0.82rem", color: "var(--text-muted)" }}>
            <Filter size={14} />
            <span>Filter By:</span>
          </div>

          <select
            className="form-control form-control-sm"
            style={{ width: "auto" }}
            value={companyFilter}
            onChange={(e) => setCompanyFilter(e.target.value)}
          >
            <option value="all">All Companies / Operators</option>
            {companyOptions.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>

          <select
            className="form-control form-control-sm"
            style={{ width: "auto" }}
            value={districtFilter}
            onChange={(e) => setDistrictFilter(e.target.value)}
          >
            <option value="all">All Districts (Goa)</option>
            <option value="north">North Goa</option>
            <option value="south">South Goa</option>
          </select>

          <select
            className="form-control form-control-sm"
            style={{ width: "auto" }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Rent Statuses</option>
            <option value="paid">Rent Cleared / Active</option>
            <option value="due_soon">Due ≤ 30 Days</option>
            <option value="overdue">Overdue Dues</option>
          </select>

          <select
            className="form-control form-control-sm"
            style={{ width: "auto" }}
            value={landFilter}
            onChange={(e) => setLandFilter(e.target.value)}
          >
            <option value="all">All Land Classifications</option>
            <option value="government">Government Plots (Panchayat/Mun.)</option>
            <option value="private">Private Properties</option>
          </select>
        </div>

        {/* Right: Search & Counts */}
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div className="table-search-wrapper" style={{ width: 280, position: "relative" }}>
            <Search size={14} className="table-search-icon" />
            <input
              type="text"
              className="table-search-input"
              placeholder="Search company, operator, ID, area..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ paddingRight: searchQuery ? "28px" : undefined }}
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery("")}
                style={{
                  position: "absolute",
                  right: 8,
                  top: "50%",
                  transform: "translateY(-50%)",
                  background: "transparent",
                  border: "none",
                  cursor: "pointer",
                  color: "var(--text-muted)",
                  padding: 2,
                  fontSize: 12,
                  display: "flex",
                  alignItems: "center",
                }}
                title="Clear search"
              >
                ✕
              </button>
            )}
          </div>

          <span
            className="badge badge-info"
            style={{ fontSize: "0.78rem", padding: "5px 12px" }}
          >
            {filteredTowers.length} of {towers.length} Mapped
          </span>
        </div>
      </div>

      {/* Map Layout Grid: Map View + Floating Details Drawer */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: selectedTower ? "1fr 340px" : "1fr",
          gap: 16,
          transition: "all 0.2s ease",
        }}
      >
        {/* Main Map Canvas */}
        <div
          className="card"
          style={{
            padding: 0,
            overflow: "hidden",
            height: "640px",
            position: "relative",
            border: "1px solid var(--border-color)",
          }}
        >
          {/* Loading Overlay */}
          {isLoading && (
            <div
              style={{
                position: "absolute",
                inset: 0,
                zIndex: 1000,
                background: "var(--bg-surface)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Loading message="Loading Goa GIS spatial telemetry map..." />
            </div>
          )}

          {/* Map Container */}
          <div
            ref={mapContainerRef}
            style={{ width: "100%", height: "100%", minHeight: "640px", zIndex: 1 }}
          />

          {/* Map Legend Overlay */}
          <div
            style={{
              position: "absolute",
              bottom: 16,
              left: 16,
              zIndex: 500,
              background: "var(--bg-surface)",
              border: "1px solid var(--border-color-light)",
              borderRadius: "var(--radius-md)",
              padding: "10px 14px",
              boxShadow: "var(--shadow-md)",
              fontSize: "0.74rem",
              display: "flex",
              flexDirection: "column",
              gap: 6,
            }}
          >
            <strong style={{ fontSize: "0.76rem", color: "var(--text-primary)" }}>
              Infrastructure Status
            </strong>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span
                style={{
                  width: 10,
                  height: 10,
                  borderRadius: "50%",
                  background: "#10b981",
                }}
              />
              <span>Rent Up-To-Date ({processedTowers.filter(t => t._status === "paid").length})</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span
                style={{
                  width: 10,
                  height: 10,
                  borderRadius: "50%",
                  background: "#f59e0b",
                }}
              />
              <span>Due ≤ 30 Days ({processedTowers.filter(t => t._status === "due_soon").length})</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span
                style={{
                  width: 10,
                  height: 10,
                  borderRadius: "50%",
                  background: "#ef4444",
                }}
              />
              <span>Overdue Default ({processedTowers.filter(t => t._status === "overdue").length})</span>
            </div>
          </div>
        </div>

        {/* Selected Tower Side Inspector */}
        {selectedTower && (
          <div
            className="card"
            style={{
              height: "640px",
              overflowY: "auto",
              display: "flex",
              flexDirection: "column",
              padding: "20px",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "flex-start",
                marginBottom: 16,
                paddingBottom: 12,
                borderBottom: "1px solid var(--border-color)",
              }}
            >
              <div>
                <span
                  style={{
                    fontSize: "0.68rem",
                    fontWeight: 800,
                    textTransform: "uppercase",
                    letterSpacing: "0.04em",
                    color:
                      selectedTower._status === "overdue"
                        ? "#ef4444"
                        : selectedTower._status === "due_soon"
                        ? "#f59e0b"
                        : "#10b981",
                  }}
                >
                  ● {selectedTower._status.replace("_", " ")}
                </span>
                <h3 style={{ fontSize: "1.2rem", margin: "4px 0 0" }}>
                  {selectedTower.tower_unique_id || `TWR-${selectedTower.id}`}
                </h3>
              </div>

              <button
                type="button"
                className="btn btn-secondary btn-icon btn-sm"
                onClick={() => setSelectedTower(null)}
              >
                ✕
              </button>
            </div>

            {/* Quick Metrics */}
            <div style={{ display: "flex", flexDirection: "column", gap: 12, flex: 1 }}>
              <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)" }}>
                <div style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Location & Jurisdiction</div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem", marginTop: 2 }}>
                  {selectedTower.area?.name || selectedTower.area_name || "Goa"}
                </div>
                <div style={{ fontSize: "0.78rem", color: "var(--text-secondary)" }}>
                  Taluka: {selectedTower.area?.taluka?.name || selectedTower.taluka?.name || selectedTower.taluka_name || "—"} · {selectedTower.area?.taluka?.constituency?.district?.name || selectedTower.district?.name || "Goa"}
                </div>
                <div style={{ fontSize: "0.72rem", fontFamily: "monospace", color: "var(--accent-cyan)", marginTop: 4 }}>
                  {selectedTower._lat.toFixed(4)}° N, {selectedTower._lng.toFixed(4)}° E
                </div>
              </div>

              <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)" }}>
                <div style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Landlord / Local Body</div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem", marginTop: 2 }}>
                  {selectedTower.owner?.name || (String(selectedTower.land_type).toLowerCase() === "government" ? "Govt. of Goa / Local Panchayat" : "Private Landowner")}
                </div>
                <div style={{ fontSize: "0.76rem", color: "var(--text-secondary)", textTransform: "capitalize" }}>
                  {selectedTower.land_type || "Government"} Land
                </div>
              </div>

              <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)" }}>
                <div style={{ fontSize: "0.72rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: 6 }}>
                  <Radio size={13} style={{ color: "var(--accent-cyan)" }} />
                  <span>Operating Telecom Company / Tenant</span>
                </div>
                {Array.isArray(selectedTower.operators) && selectedTower.operators.length > 0 ? (
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 8 }}>
                    {selectedTower.operators.map((op, i) => (
                      <span
                        key={i}
                        className="badge badge-info"
                        style={{ fontSize: "0.76rem", padding: "4px 8px" }}
                      >
                        {op.name || op.short_name}
                        {op.pivot?.frequency ? ` · ${op.pivot.frequency}` : ""}
                      </span>
                    ))}
                  </div>
                ) : (
                  <div style={{ fontWeight: 600, fontSize: "0.86rem", marginTop: 4, color: selectedTower.operator ? "var(--text-primary)" : "var(--text-muted)" }}>
                    {selectedTower.operator || "No active operator recorded"}
                  </div>
                )}
              </div>

              {/* Physical Specifications & Ground Space in Meters and Feet */}
              {(() => {
                const sHeight = parseFloat(selectedTower.height || selectedTower.height_meters || selectedTower.height_m) || 0;
                const sWidth = parseFloat(selectedTower.width || selectedTower.width_meters || selectedTower.base_width || selectedTower.width_m) || 0;
                const sHeightFt = Math.round(sHeight * 3.28084);
                const sWidthFt = Math.round(sWidth * 3.28084);
                const sAreaM2 = Math.round(sWidth * sWidth);
                const sAreaSqFt = Math.round(sAreaM2 * 10.7639);

                return (
                  <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                      <span style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Physical Specs & Dimensions</span>
                      <span style={{ fontSize: "0.72rem", color: "var(--accent-cyan)", fontWeight: 600 }}>
                        {selectedTower.tower_type || (String(selectedTower.land_type).toLowerCase() === "government" ? "Ground Based Tower" : "Rooftop / Ground Tower")}
                      </span>
                    </div>

                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 4 }}>
                      <span style={{ fontSize: "0.76rem", color: "var(--text-secondary)" }}>Tower Height</span>
                      <span style={{ fontWeight: 700, fontSize: "0.98rem", color: "var(--accent-cyan)" }}>
                        {sHeight > 0 ? (
                          <>
                            {sHeight} meters{" "}
                            <span style={{ fontSize: "0.78rem", color: "var(--text-muted)", fontWeight: 400 }}>
                              ({sHeightFt} ft)
                            </span>
                          </>
                        ) : "—"}
                      </span>
                    </div>

                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 4 }}>
                      <span style={{ fontSize: "0.76rem", color: "var(--text-secondary)" }}>Tower Space / Base</span>
                      <span style={{ fontWeight: 700, fontSize: "0.98rem", color: "var(--text-primary)" }}>
                        {sWidth > 0 ? (
                          <>
                            {sWidth} meters{" "}
                            <span style={{ fontSize: "0.78rem", color: "var(--text-muted)", fontWeight: 400 }}>
                              ({sWidthFt} ft)
                            </span>
                          </>
                        ) : "—"}
                      </span>
                    </div>

                    {sWidth > 0 && (
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", paddingTop: 4, marginTop: 4, borderTop: "1px dashed var(--border-color)" }}>
                        <span style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Ground Footprint Area</span>
                        <span style={{ fontSize: "0.78rem", color: "var(--text-secondary)", fontWeight: 600 }}>
                          {sAreaM2.toLocaleString()} m²{" "}
                          <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", fontWeight: 400 }}>
                            ({sAreaSqFt.toLocaleString()} sq ft)
                          </span>
                        </span>
                      </div>
                    )}
                  </div>
                );
              })()}

              <div style={{ background: "var(--bg-surface-elevated)", padding: "12px", borderRadius: "var(--radius-md)", border: "1px solid var(--border-color)" }}>
                <div style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>Rent & Compliance Schedule</div>
                <div style={{ fontWeight: 800, fontSize: "1.15rem", color: "#34d399", marginTop: 2 }}>
                  ₹{(parseFloat(selectedTower.yearly_rent) || (parseFloat(selectedTower.monthly_rent) || 0) * 12).toLocaleString()}{" "}
                  <span style={{ fontSize: "0.72rem", color: "var(--text-muted)", fontWeight: 400 }}>/ year</span>
                </div>
                <div style={{ fontSize: "0.78rem", color: selectedTower._status === "overdue" ? "#ef4444" : "var(--text-secondary)", marginTop: 3 }}>
                  Due Date: <strong>{selectedTower.rent_due_date ? selectedTower.rent_due_date.split("T")[0] : "Not set"}</strong>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 16 }}>
              <button
                type="button"
                className="btn btn-primary btn-sm"
                onClick={() => navigate(`/towers/${selectedTower.id}`)}
              >
                <ExternalLink size={14} />
                <span>Open Full Tower Details</span>
              </button>

              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => navigate(`/payments?action=record&tower_id=${selectedTower.id}`)}
              >
                <IndianRupee size={14} />
                <span>Record Rent Remittance</span>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default MapView;
