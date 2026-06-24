class Velocity {
  final double vNorth;
  final double vEast;
  final double vUp;

  Velocity({
    required this.vNorth,
    required this.vEast,
    required this.vUp,
  });

  factory Velocity.fromJson(Map<String, dynamic> json) {
    return Velocity(
      vNorth: (json['vNorth'] as num).toDouble(),
      vEast: (json['vEast'] as num).toDouble(),
      vUp: (json['vUp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vNorth': vNorth,
      'vEast': vEast,
      'vUp': vUp,
    };
  }
}

class TemporalContext {
  final String timestamp;
  final String validUntil;
  final Velocity velocity;

  TemporalContext({
    required this.timestamp,
    required this.validUntil,
    required this.velocity,
  });

  factory TemporalContext.fromJson(Map<String, dynamic> json) {
    return TemporalContext(
      timestamp: json['timestamp'] as String,
      validUntil: json['validUntil'] as String,
      velocity: Velocity.fromJson(json['velocity'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'validUntil': validUntil,
      'velocity': velocity.toJson(),
    };
  }
}

class PhysicalAddress {
  final String address;
  final String postalCode;
  final String state;
  final String city;
  final String countryCode;

  PhysicalAddress({
    required this.address,
    required this.postalCode,
    required this.state,
    required this.city,
    required this.countryCode,
  });

  factory PhysicalAddress.fromJson(Map<String, dynamic> json) {
    return PhysicalAddress(
      address: json['address'] as String,
      postalCode: json['postalCode'] as String,
      state: json['state'] as String,
      city: json['city'] as String,
      countryCode: json['countryCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'postalCode': postalCode,
      'state': state,
      'city': city,
      'countryCode': countryCode,
    };
  }
}

class LocationType {
  final String identity; // 'site' | 'room' | 'building'

  LocationType({
    required this.identity,
  });

  factory LocationType.fromJson(Map<String, dynamic> json) {
    return LocationType(
      identity: json['identity'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identity': identity,
    };
  }
}

class LocationHierarchy {
  final String id;
  final String name;
  final LocationType type;
  final LocationHierarchy? parent;

  LocationHierarchy({
    required this.id,
    required this.name,
    required this.type,
    this.parent,
  });

  factory LocationHierarchy.fromJson(Map<String, dynamic> json) {
    return LocationHierarchy(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LocationType.fromJson(json['type'] as Map<String, dynamic>),
      parent: json['parent'] != null
          ? LocationHierarchy.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toJson(),
      if (parent != null) 'parent': parent!.toJson(),
    };
  }
}

class RackLocation {
  final String roomName;
  final int gridRow;
  final int gridColumn;

  RackLocation({
    required this.roomName,
    required this.gridRow,
    required this.gridColumn,
  });

  factory RackLocation.fromJson(Map<String, dynamic> json) {
    return RackLocation(
      roomName: json['roomName'] as String,
      gridRow: (json['gridRow'] as num).toInt(),
      gridColumn: (json['gridColumn'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomName': roomName,
      'gridRow': gridRow,
      'gridColumn': gridColumn,
    };
  }
}

class Rack {
  final double maxVoltage;
  final double maxAllocatedPower;
  final int heightUnits;
  final RackLocation location;

  Rack({
    required this.maxVoltage,
    required this.maxAllocatedPower,
    required this.heightUnits,
    required this.location,
  });

  factory Rack.fromJson(Map<String, dynamic> json) {
    return Rack(
      maxVoltage: (json['maxVoltage'] as num).toDouble(),
      maxAllocatedPower: (json['maxAllocatedPower'] as num).toDouble(),
      heightUnits: (json['heightUnits'] as num).toInt(),
      location: RackLocation.fromJson(json['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxVoltage': maxVoltage,
      'maxAllocatedPower': maxAllocatedPower,
      'heightUnits': heightUnits,
      'location': location.toJson(),
    };
  }
}

class ContainedChassis {
  final String chassisId;
  final int startSlot;
  final int slotWidth;

  ContainedChassis({
    required this.chassisId,
    required this.startSlot,
    required this.slotWidth,
  });

  bool validateSlotOverlap(ContainedChassis other) {
    return startSlot < other.startSlot + other.slotWidth &&
        other.startSlot < startSlot + slotWidth;
  }

  factory ContainedChassis.fromJson(Map<String, dynamic> json) {
    return ContainedChassis(
      chassisId: json['chassisId'] as String,
      startSlot: (json['startSlot'] as num).toInt(),
      slotWidth: (json['slotWidth'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chassisId': chassisId,
      'startSlot': startSlot,
      'slotWidth': slotWidth,
    };
  }
}

class ChassisContainmentSubsystem {
  final List<ContainedChassis> chassis;

  ChassisContainmentSubsystem({
    required this.chassis,
  });

  bool validateAllocation() {
    for (int i = 0; i < chassis.length; i++) {
      for (int j = i + 1; j < chassis.length; j++) {
        if (chassis[i].validateSlotOverlap(chassis[j])) {
          return false;
        }
      }
    }
    return true;
  }

  factory ChassisContainmentSubsystem.fromJson(Map<String, dynamic> json) {
    return ChassisContainmentSubsystem(
      chassis: (json['chassis'] as List<dynamic>)
          .map((item) => ContainedChassis.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chassis': chassis.map((item) => item.toJson()).toList(),
    };
  }
}

/// Represents ellipsoidal coordinates.
/// @realizes UML::EllipsoidLocation
class EllipsoidLocation {
  /// The latitude.
  final double latitude;

  /// The longitude.
  final double longitude;

  /// The height.
  final double? height;

  /// Creates an [EllipsoidLocation].
  EllipsoidLocation({
    required this.latitude,
    required this.longitude,
    this.height,
  });

  /// Deserializes an [EllipsoidLocation] from JSON.
  factory EllipsoidLocation.fromJson(Map<String, dynamic> json) {
    return EllipsoidLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }

  /// Serializes an [EllipsoidLocation] to JSON.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (height != null) 'height': height,
    };
  }
}

/// Represents Cartesian coordinates.
/// @realizes UML::CartesianLocation
class CartesianLocation {
  /// The x coordinate.
  final double x;

  /// The y coordinate.
  final double y;

  /// The z coordinate.
  final double z;

  /// Creates a [CartesianLocation].
  CartesianLocation({
    required this.x,
    required this.y,
    required this.z,
  });

  /// Deserializes a [CartesianLocation] from JSON.
  factory CartesianLocation.fromJson(Map<String, dynamic> json) {
    return CartesianLocation(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  /// Serializes a [CartesianLocation] to JSON.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }
}

/// Represents a geodetic coordinate system defining the datum and accuracies.
/// @realizes UML::GeodeticSystem
class GeodeticSystem {
  /// The geodetic datum.
  final String? geodeticDatum;

  /// The coordinate accuracy.
  final double? coordAccuracy;

  /// The height accuracy.
  final double? heightAccuracy;

  /// Creates a [GeodeticSystem].
  GeodeticSystem({
    this.geodeticDatum,
    this.coordAccuracy,
    this.heightAccuracy,
  });

  /// Deserializes a [GeodeticSystem] from JSON.
  factory GeodeticSystem.fromJson(Map<String, dynamic> json) {
    return GeodeticSystem(
      geodeticDatum: (json['geodeticDatum'] ?? json['geodetic-datum']) as String?,
      coordAccuracy: (json['coordAccuracy'] ?? json['coord-accuracy']) != null
          ? ((json['coordAccuracy'] ?? json['coord-accuracy']) as num).toDouble()
          : null,
      heightAccuracy: (json['heightAccuracy'] ?? json['height-accuracy']) != null
          ? ((json['heightAccuracy'] ?? json['height-accuracy']) as num).toDouble()
          : null,
    );
  }

  /// Serializes a [GeodeticSystem] to JSON.
  Map<String, dynamic> toJson() {
    return {
      'geodeticDatum': geodeticDatum,
      'geodetic-datum': geodeticDatum,
      'coordAccuracy': coordAccuracy,
      'coord-accuracy': coordAccuracy,
      'heightAccuracy': heightAccuracy,
      'height-accuracy': heightAccuracy,
    };
  }
}

/// Represents a spatial reference frame.
/// @realizes UML::ReferenceFrame
class ReferenceFrame {
  /// The alternate system identifier.
  final String alternateSystem;

  /// The astronomical body.
  final String astronomicalBody;

  /// The geodetic system context.
  final GeodeticSystem? geodeticSystem;

  /// Creates a [ReferenceFrame].
  ReferenceFrame({
    required this.alternateSystem,
    required this.astronomicalBody,
    this.geodeticSystem,
  });

  /// Deserializes a [ReferenceFrame] from JSON.
  factory ReferenceFrame.fromJson(Map<String, dynamic> json) {
    final gsJson = json['geodeticSystem'] ?? json['geodetic-system'];
    return ReferenceFrame(
      alternateSystem: (json['alternateSystem'] ?? json['alternate-system']) as String? ?? '',
      astronomicalBody: (json['astronomicalBody'] ?? json['astronomical-body']) as String? ?? 'earth',
      geodeticSystem: gsJson != null
          ? GeodeticSystem.fromJson(gsJson as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializes a [ReferenceFrame] to JSON.
  Map<String, dynamic> toJson() {
    return {
      'alternateSystem': alternateSystem,
      'alternate-system': alternateSystem,
      'astronomicalBody': astronomicalBody,
      'astronomical-body': astronomicalBody,
      if (geodeticSystem != null) ...{
        'geodeticSystem': geodeticSystem!.toJson(),
        'geodetic-system': geodeticSystem!.toJson(),
      },
    };
  }
}

/// Represents a geographic location.
/// @realizes UML::GeoLocation
class GeoLocation {
  /// The coordinate format choice ('ellipsoid' or 'cartesian').
  final String choice;

  /// The ellipsoidal location.
  final EllipsoidLocation? ellipsoid;

  /// The Cartesian location.
  final CartesianLocation? cartesian;

  /// The velocity context.
  final Velocity? velocity;

  /// The timestamp.
  final String? timestamp;

  /// The validity limit timestamp.
  final String? validUntil;

  /// The reference frame context.
  final ReferenceFrame? referenceFrame;

  /// Creates a [GeoLocation].
  GeoLocation({
    required this.choice,
    this.ellipsoid,
    this.cartesian,
    this.velocity,
    this.timestamp,
    this.validUntil,
    this.referenceFrame,
  });

  /// Deserializes a [GeoLocation] from JSON.
  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['geo-location'] != null
        ? json['geo-location'] as Map<String, dynamic>
        : json;

    final ellJson = data['ellipsoid'];
    final cartJson = data['cartesian'];
    final velJson = data['velocity'];
    final rfJson = data['referenceFrame'] ?? data['reference-frame'];
    return GeoLocation(
      choice: data['choice'] as String? ?? 'ellipsoid',
      ellipsoid: ellJson != null
          ? EllipsoidLocation.fromJson(ellJson as Map<String, dynamic>)
          : null,
      cartesian: cartJson != null
          ? CartesianLocation.fromJson(cartJson as Map<String, dynamic>)
          : null,
      velocity: velJson != null
          ? Velocity.fromJson(velJson as Map<String, dynamic>)
          : null,
      timestamp: data['timestamp'] as String?,
      validUntil: (data['validUntil'] ?? data['valid-until']) as String?,
      referenceFrame: rfJson != null
          ? ReferenceFrame.fromJson(rfJson as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializes a [GeoLocation] to JSON.
  Map<String, dynamic> toJson() {
    final properties = <String, dynamic>{
      'choice': choice,
      if (ellipsoid != null) 'ellipsoid': ellipsoid!.toJson(),
      if (cartesian != null) 'cartesian': cartesian!.toJson(),
      if (velocity != null) 'velocity': velocity!.toJson(),
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) ...{
        'validUntil': validUntil,
        'valid-until': validUntil,
      },
      if (referenceFrame != null) ...{
        'referenceFrame': referenceFrame!.toJson(),
        'reference-frame': referenceFrame!.toJson(),
      },
    };
    return {
      ...properties,
      'geo-location': properties,
    };
  }
}

const String dummyReferenceFrame = "class reference-frame";
const String dummyGeodeticSystem = "class geodetic-system";
const String dummyGeoLocation = "class geo-location";
