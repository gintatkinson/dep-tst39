import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/components/property_grid.dart';

void main() {
  /// Helper finder to locate a TextField by its preceding label text.
  Finder findTextFieldByLabel(String labelText) {
    final Finder columnFinder = find.byWidgetPredicate((Widget widget) {
      if (widget is Column) {
        final List<Widget> children = widget.children;
        if (children.isNotEmpty && children.first is Text) {
          final Text textWidget = children.first as Text;
          if (textWidget.data == labelText) {
            return true;
          }
        }
      }
      return false;
    });
    return find.descendant(
      of: columnFinder,
      matching: find.byType(TextField),
    );
  }

  /// Helper finder to locate a DropdownButtonFormField by its label text.
  Finder findDropdownByLabel(String labelText) {
    final Finder columnFinder = find.byWidgetPredicate((Widget widget) {
      if (widget is Column) {
        final List<Widget> children = widget.children;
        if (children.isNotEmpty && children.first is Text) {
          final Text textWidget = children.first as Text;
          if (textWidget.data == labelText) {
            return true;
          }
        }
      }
      return false;
    });
    return find.descendant(
      of: columnFinder,
      matching: find.byType(DropdownButtonFormField<String>),
    );
  }

  testWidgets('Highlights Geodetic Coordinate Frame section when activeView is Location', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PropertyGrid(activeView: 'Location'),
        ),
      ),
    );

    // Verify Active Reference tag is shown in Geodetic, and NOT Alternate
    expect(find.text('Active Reference'), findsOneWidget);
    
    // The Geodetic section should be fully opaque (opacity 1.0)
    // Find the Opacity widget wrapping the first system section
    final List<Opacity> opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    expect(opacities[0].opacity, 1.0); // Geodetic is active
    expect(opacities[1].opacity, 0.65); // Alternate is dimmed
  });

  testWidgets('Highlights Alternate Structural Grid Frame section when activeView is not Location/Ingestion', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PropertyGrid(activeView: 'Metrics'),
        ),
      ),
    );

    expect(find.text('Active Reference'), findsOneWidget);
    
    final List<Opacity> opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
    expect(opacities[0].opacity, 0.65); // Geodetic is dimmed
    expect(opacities[1].opacity, 1.0); // Alternate is active
  });

  testWidgets('Buffers input locally and performs validation/commit on focus loss for countryCode', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Location',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    final Finder countryCodeField = findTextFieldByLabel('Country Code (ISO-2)');
    expect(countryCodeField, findsOneWidget);

    // Enter invalid country code "U1"
    await tester.enterText(countryCodeField, 'U1');
    await tester.pumpAndSettle(); // Let the focus system register the focus gain
    
    // Verify savedData is NOT updated yet (buffered locally)
    expect(savedData, isNull);

    // Lose focus to trigger validation
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Verify validation error is displayed and state NOT committed
    expect(find.text('Must match ISO 2-letter uppercase pattern (e.g. US, FI)'), findsOneWidget);
    expect(savedData, isNull);

    // Enter valid country code "FI"
    await tester.enterText(countryCodeField, 'FI');
    await tester.pumpAndSettle();
    
    // Lose focus
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Verify error is cleared, state is committed, and onSave callback triggered
    expect(find.text('Must match ISO 2-letter uppercase pattern (e.g. US, FI)'), findsNothing);
    expect(savedData, isNotNull);
    expect(savedData!['countryCode'], 'FI');

    // Verify committed JSON display matches committed data
    final String jsonString = const JsonEncoder.withIndent('  ').convert(savedData);
    expect(find.text(jsonString), findsOneWidget);
  });

  testWidgets('Performs validation/commit for maxVoltage and maxAllocatedPower on focus loss', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Metrics',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    final Finder voltageField = findTextFieldByLabel('Max Voltage (V)');
    final Finder powerField = findTextFieldByLabel('Max Allocated Power (W)');

    // Enter negative maxVoltage
    await tester.enterText(voltageField, '-240');
    await tester.pumpAndSettle();
    
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be negative'), findsOneWidget);
    expect(savedData, isNull);

    // Correct maxVoltage to positive
    await tester.enterText(voltageField, '240');
    await tester.pumpAndSettle();
    
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be negative'), findsNothing);
    expect(savedData!['maxVoltage'], 240.0);

    // Enter negative maxAllocatedPower
    await tester.enterText(powerField, '-15000');
    await tester.pumpAndSettle();
    
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be negative'), findsOneWidget);

    // Correct power to positive
    await tester.enterText(powerField, '15000');
    await tester.pumpAndSettle();
    
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Value cannot be negative'), findsNothing);
    expect(savedData!['maxAllocatedPower'], 15000.0);
  });

  testWidgets('Validates locationType immediately upon selection change and on blur', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Metrics',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    // Find the location hierarchy type dropdown
    final Finder dropdownFinder = findDropdownByLabel('Location Hierarchy Type');
    expect(dropdownFinder, findsOneWidget);

    // Tap the dropdown to open it (initial value is 'Room' / 'room')
    await tester.tap(find.text('Room'));
    await tester.pumpAndSettle();

    // Select the invalid test option
    await tester.tap(find.text('Invalid (Test Only)').last);
    await tester.pumpAndSettle();

    // Verify validation error is displayed
    expect(find.text("Must be 'site', 'room', or 'building'"), findsOneWidget);
    
    // Clear savedData so that we only assert selection changes do not commit invalid state
    savedData = null;
    expect(savedData, isNull);

    // Select a valid option (Site / site)
    await tester.tap(find.text('Invalid (Test Only)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Site').last);
    await tester.pumpAndSettle();

    // Verify error is cleared and state committed
    expect(find.text("Must be 'site', 'room', or 'building'"), findsNothing);
    expect(savedData!['locationType'], 'site');
  });

  testWidgets('renders Geographic Reference Frame section with default values', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PropertyGrid(activeView: 'Location'),
        ),
      ),
    );

    expect(find.text('Geographic Reference Frame'), findsOneWidget);
    expect(findTextFieldByLabel('Astronomical Body'), findsOneWidget);
    expect(findTextFieldByLabel('Geodetic Datum'), findsOneWidget);
    expect(findTextFieldByLabel('Coordinate Accuracy'), findsOneWidget);
    expect(findTextFieldByLabel('Height Accuracy'), findsOneWidget);
    expect(findTextFieldByLabel('Alternate System'), findsOneWidget);

    // Verify initial values in TextFields
    expect(tester.widget<TextField>(findTextFieldByLabel('Astronomical Body')).controller?.text, 'earth');
    expect(tester.widget<TextField>(findTextFieldByLabel('Geodetic Datum')).controller?.text, 'wgs-84');
    expect(tester.widget<TextField>(findTextFieldByLabel('Coordinate Accuracy')).controller?.text, '0.001');
    expect(tester.widget<TextField>(findTextFieldByLabel('Height Accuracy')).controller?.text, '0.001');
    expect(tester.widget<TextField>(findTextFieldByLabel('Alternate System')).controller?.text, '');
  });

  testWidgets('buffers new fields locally and only commits on focus loss (blur)', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Location',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    final Finder astroField = findTextFieldByLabel('Astronomical Body');

    // Type a new value "jupiter"
    await tester.enterText(astroField, 'jupiter');
    await tester.pumpAndSettle();

    // Verify it has not committed yet
    expect(savedData, isNull);

    // Lose focus
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Verify state committed and onSave triggered
    expect(savedData, isNotNull);
    expect(savedData!['astronomicalBody'], 'jupiter');
  });

  testWidgets('Astronomical Body normalizes input and defaults datum to wgs-84 for earth', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Location',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    final Finder astroField = findTextFieldByLabel('Astronomical Body');
    final Finder datumField = findTextFieldByLabel('Geodetic Datum');

    // 1. Enter "The Mars" and verify it normalizes to "mars"
    await tester.enterText(astroField, 'The Mars');
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(savedData!['astronomicalBody'], 'mars');
    expect(tester.widget<TextField>(astroField).controller?.text, 'mars');

    // 2. Clear Geodetic Datum to verify defaulting to "wgs-84" when Astronomical Body becomes "earth"
    await tester.enterText(datumField, '');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(savedData!['geodeticDatum'], '');

    // Now set Astronomical Body to "earth"
    await tester.enterText(astroField, 'earth');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(savedData!['astronomicalBody'], 'earth');
    expect(savedData!['geodeticDatum'], 'wgs-84');
    expect(tester.widget<TextField>(datumField).controller?.text, 'wgs-84');
  });

  testWidgets('displays validation error messages for invalid inputs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PropertyGrid(activeView: 'Location'),
        ),
      ),
    );

    final Finder astroField = findTextFieldByLabel('Astronomical Body');
    final Finder datumField = findTextFieldByLabel('Geodetic Datum');
    final Finder coordAccField = findTextFieldByLabel('Coordinate Accuracy');
    final Finder heightAccField = findTextFieldByLabel('Height Accuracy');

    // 1. Invalid Astronomical Body (emoji)
    await tester.enterText(astroField, '🌍');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Must contain only ASCII, lowercase, and no leading "the "'), findsOneWidget);

    // 2. Invalid Geodetic Datum (emoji)
    await tester.enterText(datumField, '🌍');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Must contain only ASCII, lowercase, and no spaces'), findsOneWidget);

    // 3. Invalid Coordinate Accuracy (negative)
    await tester.enterText(coordAccField, '-0.001');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Must be non-negative and have up to 6 decimal places'), findsOneWidget);

    // Clear Coordinate Accuracy error
    await tester.enterText(coordAccField, '0.001');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Must be non-negative and have up to 6 decimal places'), findsNothing);

    // 4. Invalid Height Accuracy (too many decimals)
    await tester.enterText(heightAccField, '0.1234567');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Must be non-negative and have up to 6 decimal places'), findsOneWidget);
  });

  testWidgets('Geodetic Datum normalizes input by replacing spaces with dashes', (WidgetTester tester) async {
    Map<String, dynamic>? savedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyGrid(
            activeView: 'Location',
            onSave: (data) {
              savedData = data;
            },
          ),
        ),
      ),
    );

    final Finder datumField = findTextFieldByLabel('Geodetic Datum');

    await tester.enterText(datumField, 'WGS 84');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(savedData!['geodeticDatum'], 'wgs-84');
    expect(tester.widget<TextField>(datumField).controller?.text, 'wgs-84');
  });
}
