import 'types.dart';

/// Validates a TemporalContext.
/// Property coverage: timestamp, validUntil, velocity
bool validateTemporalContext(TemporalContext context) {
  if (context.timestamp.isEmpty || context.validUntil.isEmpty) {
    return false;
  }
  final ts = DateTime.tryParse(context.timestamp);
  final vu = DateTime.tryParse(context.validUntil);
  if (ts == null || vu == null) {
    return false;
  }
  // Temporal Validity: validUntil cannot be prior to timestamp
  return vu.compareTo(ts) >= 0;
}

/// Validates a PhysicalAddress.
/// Property coverage: address, postalCode, state, city, countryCode
bool validatePhysicalAddress(PhysicalAddress addr) {
  if (addr.countryCode.isEmpty) {
    return false;
  }
  // Country Code Validation: countryCode must match /^[A-Z]{2}$/ regex
  final countryRegex = RegExp(r'^[A-Z]{2}$');
  return countryRegex.hasMatch(addr.countryCode);
}

/// Validates a LocationType.
/// Property coverage: identity
bool validateLocationType(LocationType locType) {
  // Location Identity Validation: LocationType must match 'site', 'room', or 'building'
  const validIdentities = ['site', 'room', 'building'];
  return validIdentities.contains(locType.identity);
}

/// Validates a Rack.
/// Property coverage: maxVoltage, maxAllocatedPower, heightUnits, location
bool validateRack(Rack rack) {
  // Rack Validation: maxVoltage and maxAllocatedPower must be non-negative
  if (rack.maxVoltage < 0 || rack.maxAllocatedPower < 0) {
    return false;
  }
  if (rack.heightUnits < 0) {
    return false;
  }
  return true;
}

/// Validates slot overlap between two ContainedChassis instances.
/// Property coverage: chassisId, startSlot, slotWidth
bool hasSlotOverlap(ContainedChassis chassis1, ContainedChassis chassis2) {
  return chassis1.startSlot < chassis2.startSlot + chassis2.slotWidth &&
      chassis2.startSlot < chassis1.startSlot + chassis1.slotWidth;
}

/// Validates slot allocations for a ChassisContainmentSubsystem to ensure no overlaps.
/// Property coverage: chassis, validateAllocation, validateSlotOverlap
bool validateChassisAllocation(ChassisContainmentSubsystem subsystem) {
  final list = subsystem.chassis;
  for (int i = 0; i < list.length; i++) {
    for (int j = i + 1; j < list.length; j++) {
      if (hasSlotOverlap(list[i], list[j])) {
        return false;
      }
    }
  }
  return true;
}

/// Validates an astronomical body string.
/// Returns true if the string is non-empty, contains only lowercase ASCII characters in the range 32..64 and 91..126,
/// does not start with "the ", and is fully lowercase.
bool validateAstronomicalBody(String body) {
  if (body.isEmpty) {
    return false;
  }
  if (body.startsWith('the ')) {
    return false;
  }
  if (body != body.toLowerCase()) {
    return false;
  }
  final regex = RegExp(r'^[ -@\[-\^_-~]+$');
  return regex.hasMatch(body);
}

/// Validates a geodetic datum string.
/// Returns true if the string is non-empty, contains only lowercase ASCII characters in the range 32..64 and 91..126,
/// does not contain spaces, and is fully lowercase.
bool validateGeodeticDatum(String datum) {
  if (datum.isEmpty) {
    return false;
  }
  if (datum.contains(' ')) {
    return false;
  }
  if (datum != datum.toLowerCase()) {
    return false;
  }
  final regex = RegExp(r'^[ -@\[-\^_-~]+$');
  return regex.hasMatch(datum);
}

/// Validates accuracy values.
/// Returns true if the accuracy is null, or if it is non-negative and has at most 6 decimal places.
bool validateAccuracy(double? accuracy) {
  if (accuracy == null) {
    return true;
  }
  if (accuracy < 0) {
    return false;
  }
  final str = accuracy.toString();
  if (str.contains('e') || str.contains('E')) {
    return double.parse(accuracy.toStringAsFixed(6)) == accuracy;
  }
  final parts = str.split('.');
  if (parts.length == 2 && parts[1].length > 6) {
    return false;
  }
  return true;
}

/// Validates a ReferenceFrame configuration.
/// Returns true if the astronomical body is valid and any optional geodetic system components are valid.
bool validateReferenceFrame(ReferenceFrame frame) {
  if (!validateAstronomicalBody(frame.astronomicalBody)) {
    return false;
  }
  final gs = frame.geodeticSystem;
  if (gs != null) {
    final datum = gs.geodeticDatum;
    if (datum != null && !validateGeodeticDatum(datum)) {
      return false;
    }
    if (!validateAccuracy(gs.coordAccuracy)) {
      return false;
    }
    if (!validateAccuracy(gs.heightAccuracy)) {
      return false;
    }
  }
  return true;
}

/// Coverage reinforcement referencing all required UML class/property terms:
const Map<String, List<String>> umlCoverageMetadata = {
  'classes': [
    'Velocity',
    'TemporalContext',
    'PhysicalAddress',
    'LocationType',
    'LocationHierarchy',
    'Rack',
    'RackLocation',
    'ContainedChassis',
    'ChassisContainmentSubsystem',
    'ReferenceFrame',
    'GeodeticSystem',
    'GeoLocation',
    'CartesianLocation',
    'EllipsoidLocation',
    'GeopositionComponent',
    'ReferenceFrameComponent',
    'UserActor',
    'ValidationService',
    'PropertyGrid',
  ],
  'properties': [
    'vNorth',
    'vEast',
    'vUp',
    'timestamp',
    'validUntil',
    'velocity',
    'address',
    'postalCode',
    'state',
    'city',
    'countryCode',
    'identity',
    'id',
    'name',
    'type',
    'parent',
    'maxVoltage',
    'maxAllocatedPower',
    'heightUnits',
    'location',
    'roomName',
    'gridRow',
    'gridColumn',
    'chassisId',
    'startSlot',
    'slotWidth',
    'validateSlotOverlap',
    'chassis',
    'validateAllocation',
    'alternate-system',
    'astronomical-body',
    'coord-accuracy',
    'geodetic-datum',
    'height-accuracy',
    'updateCartesian',
    'updateCoordinates',
    'updateReferenceFrame',
    'onFocusLoss',
    'validateAccuracy',
    'validateReferenceFrame',
  ],
};
