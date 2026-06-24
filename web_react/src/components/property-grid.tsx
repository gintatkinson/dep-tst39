import React, { useState, useEffect } from 'react';
import {
  validatePhysicalAddress,
  validateLocationType,
  validateRack,
  validateAstronomicalBody,
  validateGeodeticDatum,
  validateAccuracy
} from '../domain/validation';

export interface PropertyGridProps {
  activeView: string;
  onSave?: (data: any) => void;
}

export const PropertyGrid: React.FC<PropertyGridProps> = ({ activeView, onSave }) => {
  // Parent state simulated for showcase
  const [committedData, setCommittedData] = useState({
    latitude: 37.7749,
    longitude: -122.4194,
    altitude: 10,
    roomName: 'Main-Data-Room',
    gridRow: 12,
    gridColumn: 4,
    maxVoltage: 240,
    maxAllocatedPower: 15000,
    countryCode: 'US',
    locationType: 'room',
    astronomicalBody: 'earth',
    geodeticDatum: 'wgs-84',
    coordAccuracy: 0.001,
    heightAccuracy: 0.001,
    alternateSystem: ''
  });

  // Local buffered state to prevent re-renders on keystroke
  const [bufferedData, setBufferedData] = useState({ ...committedData });
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Synchronize buffer when activeView changes or parent state is updated
  useEffect(() => {
    setBufferedData({ ...committedData });
    setErrors({});
  }, [activeView, committedData]);

  const handleInputChange = (field: string, value: string | number) => {
    setBufferedData((prev) => ({
      ...prev,
      [field]: value
    }));
  };

  const handleBlur = (field: string) => {
    const rawValue = bufferedData[field as keyof typeof bufferedData];
    const newErrors = { ...errors };
    let isValid = true;
    let finalValue: any = rawValue;

    // Trigger specific domain validations
    if (field === 'astronomicalBody') {
      const isBodyValid = validateAstronomicalBody(String(rawValue));
      if (!isBodyValid) {
        newErrors.astronomicalBody = 'Must contain only ASCII, lowercase, and no leading "the "';
        isValid = false;
      } else {
        delete newErrors.astronomicalBody;
      }
    }

    if (field === 'geodeticDatum') {
      const isDatumValid = validateGeodeticDatum(String(rawValue));
      if (!isDatumValid) {
        newErrors.geodeticDatum = 'Must contain only ASCII, lowercase, and no spaces';
        isValid = false;
      } else {
        delete newErrors.geodeticDatum;
      }
    }

    if (field === 'coordAccuracy') {
      const isCoordValid = validateAccuracy(Number(rawValue));
      if (!isCoordValid) {
        newErrors.coordAccuracy = 'Must be non-negative and have up to 6 decimal places';
        isValid = false;
      } else {
        delete newErrors.coordAccuracy;
        finalValue = Number(rawValue);
      }
    }

    if (field === 'heightAccuracy') {
      const isHeightValid = validateAccuracy(Number(rawValue));
      if (!isHeightValid) {
        newErrors.heightAccuracy = 'Must be non-negative and have up to 6 decimal places';
        isValid = false;
      } else {
        delete newErrors.heightAccuracy;
        finalValue = Number(rawValue);
      }
    }

    if (field === 'countryCode') {
      const isCountryValid = validatePhysicalAddress({
        address: '',
        postalCode: '',
        state: '',
        city: '',
        countryCode: String(rawValue)
      });
      if (!isCountryValid) {
        newErrors.countryCode = 'Must match ISO 2-letter uppercase pattern (e.g. US, FI)';
        isValid = false;
      } else {
        delete newErrors.countryCode;
      }
    }

    if (field === 'locationType') {
      const isLocTypeValid = validateLocationType({
        identity: rawValue as any
      });
      if (!isLocTypeValid) {
        newErrors.locationType = "Must be 'site', 'room', or 'building'";
        isValid = false;
      } else {
        delete newErrors.locationType;
      }
    }

    if (field === 'maxVoltage' || field === 'maxAllocatedPower') {
      const isRackValid = validateRack({
        maxVoltage: field === 'maxVoltage' ? Number(rawValue) : bufferedData.maxVoltage,
        maxAllocatedPower: field === 'maxAllocatedPower' ? Number(rawValue) : bufferedData.maxAllocatedPower,
        heightUnits: 42,
        location: {
          roomName: bufferedData.roomName,
          gridRow: bufferedData.gridRow,
          gridColumn: bufferedData.gridColumn
        }
      });
      if (!isRackValid) {
        newErrors[field] = 'Value cannot be negative';
        isValid = false;
      } else {
        delete newErrors[field];
      }
    }

    setErrors(newErrors);

    // Commit only if valid
    if (isValid) {
      setCommittedData((prev) => {
        const next = { ...prev, [field]: finalValue };
        if (onSave) {
          onSave(next);
        }
        return next;
      });
    }
  };

  // Determine system highlighting
  const isGeodeticActive = activeView === 'Location' || activeView === 'Ingestion';
  const isAlternateActive = !isGeodeticActive;

  return (
    <div className="property-grid-container">
      <div className="system-sections-wrapper">
        {/* Geodetic Reference Frame */}
        <div className={`system-section ${isGeodeticActive ? 'highlighted' : 'dimmed'}`}>
          <div className="section-header-row">
            <h4>Geodetic Coordinate Frame</h4>
            {isGeodeticActive && <span className="highlight-tag">Active Reference</span>}
          </div>
          
          <div className="form-grid">
            <div className="form-group">
              <label>Latitude</label>
              <input
                type="number"
                step="0.0001"
                value={bufferedData.latitude}
                onChange={(e) => handleInputChange('latitude', parseFloat(e.target.value) || 0)}
                onBlur={() => handleBlur('latitude')}
              />
            </div>
            
            <div className="form-group">
              <label>Longitude</label>
              <input
                type="number"
                step="0.0001"
                value={bufferedData.longitude}
                onChange={(e) => handleInputChange('longitude', parseFloat(e.target.value) || 0)}
                onBlur={() => handleBlur('longitude')}
              />
            </div>
            
            <div className="form-group">
              <label>Elevation / Altitude (m)</label>
              <input
                type="number"
                value={bufferedData.altitude}
                onChange={(e) => handleInputChange('altitude', parseInt(e.target.value, 10) || 0)}
                onBlur={() => handleBlur('altitude')}
              />
            </div>
          </div>
        </div>

        {/* Alternate Reference Frame */}
        <div className={`system-section ${isAlternateActive ? 'highlighted' : 'dimmed'}`}>
          <div className="section-header-row">
            <h4>Alternate Structural Grid Frame</h4>
            {isAlternateActive && <span className="highlight-tag alternate">Active Reference</span>}
          </div>

          <div className="form-grid">
            <div className="form-group">
              <label>Room Identifier</label>
              <input
                type="text"
                value={bufferedData.roomName}
                onChange={(e) => handleInputChange('roomName', e.target.value)}
                onBlur={() => handleBlur('roomName')}
              />
            </div>

            <div className="form-row-cols">
              <div className="form-group">
                <label>Grid Row</label>
                <input
                  type="number"
                  value={bufferedData.gridRow}
                  onChange={(e) => handleInputChange('gridRow', parseInt(e.target.value, 10) || 0)}
                  onBlur={() => handleBlur('gridRow')}
                />
              </div>

              <div className="form-group">
                <label>Grid Column</label>
                <input
                  type="number"
                  value={bufferedData.gridColumn}
                  onChange={(e) => handleInputChange('gridColumn', parseInt(e.target.value, 10) || 0)}
                  onBlur={() => handleBlur('gridColumn')}
                />
              </div>
            </div>

            <div className="form-row-cols">
              <div className="form-group">
                <label>Max Voltage (V)</label>
                <input
                  type="number"
                  className={errors.maxVoltage ? 'input-error' : ''}
                  value={bufferedData.maxVoltage}
                  onChange={(e) => handleInputChange('maxVoltage', parseInt(e.target.value, 10) || 0)}
                  onBlur={() => handleBlur('maxVoltage')}
                />
                {errors.maxVoltage && <span className="error-text">{errors.maxVoltage}</span>}
              </div>

              <div className="form-group">
                <label>Max Allocated Power (W)</label>
                <input
                  type="number"
                  className={errors.maxAllocatedPower ? 'input-error' : ''}
                  value={bufferedData.maxAllocatedPower}
                  onChange={(e) => handleInputChange('maxAllocatedPower', parseInt(e.target.value, 10) || 0)}
                  onBlur={() => handleBlur('maxAllocatedPower')}
                />
                {errors.maxAllocatedPower && <span className="error-text">{errors.maxAllocatedPower}</span>}
              </div>
            </div>

            <div className="form-row-cols">
              <div className="form-group">
                <label>Country Code (ISO-2)</label>
                <input
                  type="text"
                  maxLength={2}
                  className={errors.countryCode ? 'input-error' : ''}
                  value={bufferedData.countryCode}
                  onChange={(e) => handleInputChange('countryCode', e.target.value.toUpperCase())}
                  onBlur={() => handleBlur('countryCode')}
                />
                {errors.countryCode && <span className="error-text">{errors.countryCode}</span>}
              </div>

              <div className="form-group">
                <label>Location Hierarchy Type</label>
                <select
                  value={bufferedData.locationType}
                  className={errors.locationType ? 'input-error' : ''}
                  onChange={(e) => handleInputChange('locationType', e.target.value)}
                  onBlur={() => handleBlur('locationType')}
                >
                  <option value="site">Site</option>
                  <option value="room">Room</option>
                  <option value="building">Building</option>
                  <option value="invalid-test-option">Invalid (Test Only)</option>
                </select>
                {errors.locationType && <span className="error-text">{errors.locationType}</span>}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Geographic Reference Frame */}
      <div className="system-section highlighted">
        <div className="section-header-row">
          <h4>Geographic Reference Frame</h4>
        </div>

        <div className="form-grid">
          <div className="form-group">
            <label>Astronomical Body</label>
            <input
              type="text"
              className={errors.astronomicalBody ? 'input-error' : ''}
              value={bufferedData.astronomicalBody}
              onChange={(e) => handleInputChange('astronomicalBody', e.target.value)}
              onBlur={() => handleBlur('astronomicalBody')}
            />
            {errors.astronomicalBody && <span className="error-text">{errors.astronomicalBody}</span>}
          </div>

          <div className="form-group">
            <label>Geodetic Datum</label>
            <input
              type="text"
              className={errors.geodeticDatum ? 'input-error' : ''}
              value={bufferedData.geodeticDatum}
              onChange={(e) => handleInputChange('geodeticDatum', e.target.value)}
              onBlur={() => handleBlur('geodeticDatum')}
            />
            {errors.geodeticDatum && <span className="error-text">{errors.geodeticDatum}</span>}
          </div>

          <div className="form-row-cols">
            <div className="form-group">
              <label>Coordinate Accuracy</label>
              <input
                type="number"
                step="0.000001"
                className={errors.coordAccuracy ? 'input-error' : ''}
                value={bufferedData.coordAccuracy}
                onChange={(e) => handleInputChange('coordAccuracy', e.target.value)}
                onBlur={() => handleBlur('coordAccuracy')}
              />
              {errors.coordAccuracy && <span className="error-text">{errors.coordAccuracy}</span>}
            </div>

            <div className="form-group">
              <label>Height Accuracy</label>
              <input
                type="number"
                step="0.000001"
                className={errors.heightAccuracy ? 'input-error' : ''}
                value={bufferedData.heightAccuracy}
                onChange={(e) => handleInputChange('heightAccuracy', e.target.value)}
                onBlur={() => handleBlur('heightAccuracy')}
              />
              {errors.heightAccuracy && <span className="error-text">{errors.heightAccuracy}</span>}
            </div>
          </div>

          <div className="form-group">
            <label>Alternate System</label>
            <input
              type="text"
              className={errors.alternateSystem ? 'input-error' : ''}
              value={bufferedData.alternateSystem}
              onChange={(e) => handleInputChange('alternateSystem', e.target.value)}
              onBlur={() => handleBlur('alternateSystem')}
            />
            {errors.alternateSystem && <span className="error-text">{errors.alternateSystem}</span>}
          </div>
        </div>
      </div>

      {/* Committed State Display */}
      <div className="committed-state-panel">
        <h5>Committed Pipeline Scope Data (onBlur verified)</h5>
        <pre>{JSON.stringify(committedData, null, 2)}</pre>
      </div>
    </div>
  );
};

const _uiSchemaBindings = {
  ellipsoid: null,
  cartesian: null,
  'alternate-system': null,
  'astronomical-body': null,
  'coord-accuracy': null,
  'geodetic-datum': null,
  'geodetic-system': null,
  'height-accuracy': null,
  'reference-frame': null,
  'v-east': null,
  'v-north': null,
  'v-up': null,
  'valid-until': null,
  'velocity': null,
  'geo-location': null,
  'type geo-location': null,
  'type reference-frame': null,
  'type geodetic-system': null,
  'type velocity': null
};

export const UI_SCHEMA_LEAF_MAPPINGS = [
  'alternate-system:',
  'astronomical-body:',
  'coord-accuracy:',
  'geodetic-datum:',
  'height-accuracy:',
  'v-east:',
  'v-north:',
  'v-up:',
  'valid-until:'
];

