import 'dart:math' as math;

import 'package:dart_console/dart_console.dart';
import 'package:test/test.dart';

const earlyPresidents = [
  [1, 'April 30, 1789 - March 4, 1797', 'George Washington', 'unaffiliated'],
  [2, 'March 4, 1797 - March 4, 1801', 'John Adams', 'Federalist'],
  [
    3,
    'March 4, 1801 - March 4, 1809',
    'Thomas Jefferson',
    'Democratic-Republican',
  ],
  [
    4,
    'March 4, 1809 - March 4, 1817',
    'James Madison',
    'Democratic-Republican',
  ],
  [5, 'March 4, 1817 - March 4, 1825', 'James Monroe', 'Democratic-Republican'],
];

const planets = [
  ['Mercury', '5.7909227 × 10⁷'],
  ['Venus', '1.0820948 × 10⁸'],
  ['Earth', '1.4959826 × 10⁸'],
  ['Mars', '2.2794382 × 10⁸'],
  ['Jupiter', '7.7834082 × 10⁸'],
  ['Saturn', '1.4266664 × 10⁹'],
  ['Uranus', '2.8706582 × 10⁹'],
  ['Neptune', '4.4983964 × 10⁹'],
  // sorry Pluto :(
];

void main() {
  group('Table operations', () {
    test('Empty table should not render', () {
      final table = Table();
      expect(table.toString(), isEmpty);
    });

    test('Table with no column defs should not render header', () {
      final table = Table()..insertRows(earlyPresidents);
      expect(
        table.toString(),
        equals('''
╭───┬────────────────────────────────┬───────────────────┬───────────────────────╮
│ 1 │ April 30, 1789 - March 4, 1797 │ George Washington │ unaffiliated          │
│ 2 │ March 4, 1797 - March 4, 1801  │ John Adams        │ Federalist            │
│ 3 │ March 4, 1801 - March 4, 1809  │ Thomas Jefferson  │ Democratic-Republican │
│ 4 │ March 4, 1809 - March 4, 1817  │ James Madison     │ Democratic-Republican │
│ 5 │ March 4, 1817 - March 4, 1825  │ James Monroe      │ Democratic-Republican │
╰───┴────────────────────────────────┴───────────────────┴───────────────────────╯
'''),
      );
    });

    test('Can add columns and make other changes after table is defined', () {
      final table = Table()
        ..insertColumn(header: 'Planet')
        ..insertColumn(
          header: 'Orbital Distance',
          alignment: TextAlignment.right,
        )
        ..insertRows(planets)
        ..borderStyle = BorderStyle.square;

      table
        ..insertColumn(header: 'Mass')
        ..insertColumn(header: 'Radius', index: 1)
        ..insertColumn(header: 'Density')
        ..borderStyle = BorderStyle.rounded;

      expect(
        table.toString(),
        equals('''
╭─────────┬────────┬──────────────────┬──────┬─────────╮
│ Planet  │ Radius │ Orbital Distance │ Mass │ Density │
├─────────┼────────┼──────────────────┼──────┼─────────┤
│ Mercury │        │  5.7909227 × 10⁷ │      │         │
│ Venus   │        │  1.0820948 × 10⁸ │      │         │
│ Earth   │        │  1.4959826 × 10⁸ │      │         │
│ Mars    │        │  2.2794382 × 10⁸ │      │         │
│ Jupiter │        │  7.7834082 × 10⁸ │      │         │
│ Saturn  │        │  1.4266664 × 10⁹ │      │         │
│ Uranus  │        │  2.8706582 × 10⁹ │      │         │
│ Neptune │        │  4.4983964 × 10⁹ │      │         │
╰─────────┴────────┴──────────────────┴──────┴─────────╯
'''),
      );
    });

    test('Removing all columns should leave an empty table', () {
      final table = Table()..insertRows(planets);
      table
        ..deleteColumn(1)
        ..deleteColumn(0);
      expect(table.toString(), isEmpty);
    });

    test('Not possible to remove more columns than exist', () {
      final table = Table()..insertRows(planets);
      table
        ..deleteColumn(1)
        ..deleteColumn(0);
      expect(() => table.deleteColumn(0), throwsArgumentError);
    });

    test('Delete rows', () {
      final table = Table()..insertRows(planets);
      expect(() => table.deleteRow(table.rows + 1), throwsArgumentError);
      expect(() => table.deleteRow(table.rows), throwsArgumentError);
      expect(() => table.deleteRow(-1), throwsArgumentError);

      expect(table.rows, equals(8));
      expect(() => table.deleteRow(table.rows - 1), returnsNormally);
      expect(table.toString(), isNot(contains('Neptune')));
      expect(table.toString(), contains('Uranus'));

      expect(table.rows, equals(7));
      expect(() => table.deleteRow(0), returnsNormally);
      expect(table.toString(), isNot(contains('Mercury')));

      expect(table.rows, equals(6));
    });

    test('Add rows without column definitions should give a valid result', () {
      final table = Table()..insertRows(planets);
      expect(
        table.toString(),
        equals('''
╭─────────┬─────────────────╮
│ Mercury │ 5.7909227 × 10⁷ │
│ Venus   │ 1.0820948 × 10⁸ │
│ Earth   │ 1.4959826 × 10⁸ │
│ Mars    │ 2.2794382 × 10⁸ │
│ Jupiter │ 7.7834082 × 10⁸ │
│ Saturn  │ 1.4266664 × 10⁹ │
│ Uranus  │ 2.8706582 × 10⁹ │
│ Neptune │ 4.4983964 × 10⁹ │
╰─────────┴─────────────────╯
'''),
      );
    });

    test('Delete rows', () {
      final table = Table()..insertRows(planets);

      table.deleteRow(2);
      expect(table.toString, isNot(contains('Earth')));
    });

    test('Different types', () {
      final table = Table()
        ..borderColor = ConsoleColor.brightGreen
        ..borderStyle = BorderStyle.double
        ..borderType = BorderType.grid
        ..headerStyle = FontStyle.boldUnderscore
        ..insertColumn(header: 'Strings', alignment: TextAlignment.left)
        ..insertColumn(header: 'Coordinates', alignment: TextAlignment.right)
        ..insertColumn(header: 'Integers', alignment: TextAlignment.right)
        ..insertColumn(header: 'Doubles', alignment: TextAlignment.right)
        ..insertRow(['qwertyuiop', Coordinate(0, 0), 0, 1.234567])
        ..insertRow(['asdfghjkl', Coordinate(80, 24), 2 << 60, math.pi])
        ..insertRow(['zxcvbnm', Coordinate(17, 17), 42, math.e]);
      expect(
        table.render(),
        equals('''
[92m╔════════════╦═════════════╦═════════════════════╦═══════════════════╗[m
[92m║ [m[1;4mStrings   [m[92m ║ [m[1;4mCoordinates[m[92m ║ [m[1;4m           Integers[m[92m ║ [m[1;4m          Doubles[m[92m ║[m
[92m╠════════════╬═════════════╬═════════════════════╬═══════════════════╣[m
[92m║ [mqwertyuiop[92m ║ [m     (0, 0)[92m ║ [m                  0[92m ║ [m         1.234567[92m ║[m
[92m╠════════════╬═════════════╬═════════════════════╬═══════════════════╣[m
[92m║ [masdfghjkl [92m ║ [m   (80, 24)[92m ║ [m2305843009213693952[92m ║ [m3.141592653589793[92m ║[m
[92m╠════════════╬═════════════╬═════════════════════╬═══════════════════╣[m
[92m║ [mzxcvbnm   [92m ║ [m   (17, 17)[92m ║ [m                 42[92m ║ [m2.718281828459045[92m ║[m
[92m╚════════════╩═════════════╩═════════════════════╩═══════════════════╝[m
'''),
      );
    });

    test('Add a row with too many columns should crop remaining columns', () {
      final table = Table()
        ..borderStyle = BorderStyle.none
        ..insertColumn(header: 'Column 1')
        ..insertColumn(header: 'Column 2')
        ..insertColumn(header: 'Column 3')
        ..insertRows([
          ['1', '2', '3'],
          ['a', 'b', 'c', 'd'],
        ]);
      expect(table.toString(), isNot(contains('d')));
    });

    test('Adding a sparse row should not throw an error', () {
      final table = Table()
        ..borderStyle = BorderStyle.none
        ..insertColumn(header: 'Column 1')
        ..insertColumn(header: 'Column 2')
        ..insertColumn(header: 'Column 3')
        ..insertRows([
          ['1', '2', '3'],
          ['a', 'b'],
          ['_'],
          [],
        ]);

      expect(
        table.toString(),
        equals('''
Column 1 Column 2 Column 3
1        2        3       
a        b                
_                         
                          
'''),
      );
      expect(table.rows, equals(4));
    });
  });

  group('Table formatting', () {
    test('None', () {
      final table = Table()
        ..borderStyle = BorderStyle.none
        ..headerStyle = FontStyle.underscore
        ..insertColumn(header: 'Fruit')
        ..insertColumn(header: 'Qty', alignment: TextAlignment.right)
        ..insertRows([
          ['apples', 10],
          ['bananas', 5],
          ['apricots', 7],
        ]);
      expect(
        table.toString(),
        equals('''
[4mFruit   [m [4mQty[m
apples    10
bananas    5
apricots   7
'''),
      );
    });

    test('ASCII grid', () {
      final table = Table()
        ..borderStyle = BorderStyle.ascii
        ..borderType = BorderType.grid
        ..insertColumn(header: 'Fruit')
        ..insertColumn(header: 'Qty', alignment: TextAlignment.right)
        ..insertColumn(header: 'Notes')
        ..insertRows([
          ['apples', '10'],
          ['bananas', '5'],
          ['apricots', '7'],
        ])
        ..insertRow(['dates', '10000', 'a big number'])
        ..insertRow(['kumquats', '59']);
      expect(
        table.toString(),
        equals('''
-----------------------------------
| Fruit    |   Qty | Notes        |
|----------+-------+--------------|
| apples   |    10 |              |
|----------+-------+--------------|
| bananas  |     5 |              |
|----------+-------+--------------|
| apricots |     7 |              |
|----------+-------+--------------|
| dates    | 10000 | a big number |
|----------+-------+--------------|
| kumquats |    59 |              |
-----------------------------------
'''),
      );
    });

    test('ASCII header', () {
      final table = Table()
        ..borderStyle = BorderStyle.ascii
        ..borderType = BorderType.header
        ..insertColumn(header: 'Fruit')
        ..insertColumn(header: 'Qty', alignment: TextAlignment.right)
        ..insertColumn(header: 'Notes')
        ..insertRows([
          ['apples', '10'],
          ['bananas', '5'],
          ['apricots', '7'],
        ])
        ..insertRow(['dates', '10000', 'a big number'])
        ..insertRow(['kumquats', '59']);
      expect(
        table.toString(),
        equals('''
-----------------------------------
| Fruit    |   Qty | Notes        |
|----------+-------+--------------|
| apples   |    10 |              |
| bananas  |     5 |              |
| apricots |     7 |              |
| dates    | 10000 | a big number |
| kumquats |    59 |              |
-----------------------------------
'''),
      );
    });

    test('ASCII outline', () {
      final table = Table()
        ..borderStyle = BorderStyle.ascii
        ..borderType = BorderType.outline
        ..insertColumn(header: 'Fruit')
        ..insertColumn(header: 'Qty', alignment: TextAlignment.right)
        ..insertRows([
          ['apples', 10],
          ['bananas', 5],
          ['apricots', 7],
        ]);
      expect(
        table.toString(),
        equals('''
----------------
| Fruit    Qty |
|              |
| apples    10 |
| bananas    5 |
| apricots   7 |
----------------
'''),
      );
    });

    test('Borderless table', () {
      final table = Table()
        ..borderStyle = BorderStyle.none
        ..borderType = BorderType.header
        ..insertColumn(header: 'Fruit')
        ..insertColumn(header: 'Qty', alignment: TextAlignment.right)
        ..insertColumn(header: 'Notes')
        ..insertRows([
          ['apples', '10'],
          ['bananas', '5'],
          ['apricots', '7'],
        ])
        ..insertRow(['dates', '10000', 'a big number'])
        ..insertRow(['kumquats', '59']);

      final golden = '''
Fruit      Qty Notes       
apples      10             
bananas      5             
apricots     7             
dates    10000 a big number
kumquats    59             
''';
      expect(table.toString(), equals(golden));

      // Changing border type shouldn't have any impact if there's no border
      table.borderType = BorderType.grid;
      expect(table.toString(), equals(golden));

      table.borderType = BorderType.outline;
      expect(table.toString(), equals(golden));
    });

    test('Glyphs', () {
      final table = Table()
        ..insertColumn(header: 'Number', alignment: TextAlignment.right)
        ..insertColumn(header: 'Presidency')
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents)
        ..borderStyle = BorderStyle.square;

      expect(
        table.toString(),
        equals('''
┌────────┬────────────────────────────────┬───────────────────┬───────────────────────┐
│ Number │ Presidency                     │ President         │ Party                 │
├────────┼────────────────────────────────┼───────────────────┼───────────────────────┤
│      1 │ April 30, 1789 - March 4, 1797 │ George Washington │ unaffiliated          │
│      2 │ March 4, 1797 - March 4, 1801  │ John Adams        │ Federalist            │
│      3 │ March 4, 1801 - March 4, 1809  │ Thomas Jefferson  │ Democratic-Republican │
│      4 │ March 4, 1809 - March 4, 1817  │ James Madison     │ Democratic-Republican │
│      5 │ March 4, 1817 - March 4, 1825  │ James Monroe      │ Democratic-Republican │
└────────┴────────────────────────────────┴───────────────────┴───────────────────────┘
'''),
      );
    });

    test('Color border', () {
      final table = Table()
        ..borderColor = ConsoleColor.brightCyan
        ..borderStyle = BorderStyle.bold
        ..insertColumn(header: 'Number', alignment: TextAlignment.right)
        ..insertColumn(header: 'Presidency')
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents);

      expect(
        table.toString(),
        equals('''
[96m┏━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┓[m
[96m┃ [mNumber[96m ┃ [mPresidency                    [96m ┃ [mPresident        [96m ┃ [mParty                [96m ┃[m
[96m┣━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━┫[m
[96m┃ [m     1[96m ┃ [mApril 30, 1789 - March 4, 1797[96m ┃ [mGeorge Washington[96m ┃ [munaffiliated         [96m ┃[m
[96m┃ [m     2[96m ┃ [mMarch 4, 1797 - March 4, 1801 [96m ┃ [mJohn Adams       [96m ┃ [mFederalist           [96m ┃[m
[96m┃ [m     3[96m ┃ [mMarch 4, 1801 - March 4, 1809 [96m ┃ [mThomas Jefferson [96m ┃ [mDemocratic-Republican[96m ┃[m
[96m┃ [m     4[96m ┃ [mMarch 4, 1809 - March 4, 1817 [96m ┃ [mJames Madison    [96m ┃ [mDemocratic-Republican[96m ┃[m
[96m┃ [m     5[96m ┃ [mMarch 4, 1817 - March 4, 1825 [96m ┃ [mJames Monroe     [96m ┃ [mDemocratic-Republican[96m ┃[m
[96m┗━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━┛[m
'''),
      );
    });

    test('Horizontal double border', () {
      final table = Table()
        ..borderColor = ConsoleColor.blue
        ..borderStyle = BorderStyle.double
        ..borderType = BorderType.horizontal
        ..insertColumn(header: 'Number', alignment: TextAlignment.center)
        ..insertColumn(header: 'Presidency', alignment: TextAlignment.right)
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents);

      expect(
        table.toString(),
        equals('''
[34m╔═════════════════════════════════════════════════════════════════════════════════════╗[m
[34m║ [mNumber                       Presidency   President           Party                [34m ║[m
[34m╠═════════════════════════════════════════════════════════════════════════════════════╣[m
[34m║ [m   1     April 30, 1789 - March 4, 1797   George Washington   unaffiliated         [34m ║[m
[34m║ [m   2      March 4, 1797 - March 4, 1801   John Adams          Federalist           [34m ║[m
[34m║ [m   3      March 4, 1801 - March 4, 1809   Thomas Jefferson    Democratic-Republican[34m ║[m
[34m║ [m   4      March 4, 1809 - March 4, 1817   James Madison       Democratic-Republican[34m ║[m
[34m║ [m   5      March 4, 1817 - March 4, 1825   James Monroe        Democratic-Republican[34m ║[m
[34m╚═════════════════════════════════════════════════════════════════════════════════════╝[m
'''),
      );
    });

    test('Rounded border vertical', () {
      final table = Table();
      table
        ..borderColor = ConsoleColor.green
        ..borderStyle = BorderStyle.rounded
        ..borderType = BorderType.vertical
        ..insertColumn(header: 'Number', alignment: TextAlignment.right)
        ..insertColumn(header: 'Presidency')
        ..insertColumn(header: 'President')
        ..insertRows(earlyPresidents.take(3).toList());

      expect(
        table.toString(),
        equals('''
[32m╭────────┬────────────────────────────────┬───────────────────╮[m
[32m│ [mNumber[32m │ [mPresidency                    [32m │ [mPresident        [32m │[m
[32m│        │                                │                   │[m
[32m│ [m     1[32m │ [mApril 30, 1789 - March 4, 1797[32m │ [mGeorge Washington[32m │[m
[32m│ [m     2[32m │ [mMarch 4, 1797 - March 4, 1801 [32m │ [mJohn Adams       [32m │[m
[32m│ [m     3[32m │ [mMarch 4, 1801 - March 4, 1809 [32m │ [mThomas Jefferson [32m │[m
[32m╰────────┴────────────────────────────────┴───────────────────╯[m
'''),
      );
    });

    test('Wrapped text', () {
      final table = Table()
        ..borderStyle = BorderStyle.rounded
        ..borderType = BorderType.grid
        ..insertColumn(header: 'Number', alignment: TextAlignment.center)
        ..insertColumn(
          header: 'Presidency',
          alignment: TextAlignment.right,
          width: 18,
        )
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents);

      expect(
        table.toString(),
        equals('''
╭────────┬────────────────────┬───────────────────┬───────────────────────╮
│ Number │         Presidency │ President         │ Party                 │
├────────┼────────────────────┼───────────────────┼───────────────────────┤
│    1   │   April 30, 1789 - │ George Washington │ unaffiliated          │
│        │      March 4, 1797 │                   │                       │
├────────┼────────────────────┼───────────────────┼───────────────────────┤
│    2   │    March 4, 1797 - │ John Adams        │ Federalist            │
│        │      March 4, 1801 │                   │                       │
├────────┼────────────────────┼───────────────────┼───────────────────────┤
│    3   │    March 4, 1801 - │ Thomas Jefferson  │ Democratic-Republican │
│        │      March 4, 1809 │                   │                       │
├────────┼────────────────────┼───────────────────┼───────────────────────┤
│    4   │    March 4, 1809 - │ James Madison     │ Democratic-Republican │
│        │      March 4, 1817 │                   │                       │
├────────┼────────────────────┼───────────────────┼───────────────────────┤
│    5   │    March 4, 1817 - │ James Monroe      │ Democratic-Republican │
│        │      March 4, 1825 │                   │                       │
╰────────┴────────────────────┴───────────────────┴───────────────────────╯
'''),
      );
    });

    test('Borders do not render when style is none', () {
      final table = Table()
        ..insertColumn(header: 'Planet')
        ..insertColumn(
          header: 'Orbital Distance',
          alignment: TextAlignment.right,
        )
        ..insertRows(planets)
        ..headerStyle = FontStyle.boldUnderscore
        ..borderStyle = BorderStyle.none
        ..borderColor = ConsoleColor.brightRed
        ..borderType = BorderType.vertical;

      expect(
        table.toString(),
        equals('''
[1;4mPlanet [m [1;4mOrbital Distance[m
Mercury  5.7909227 × 10⁷
Venus    1.0820948 × 10⁸
Earth    1.4959826 × 10⁸
Mars     2.2794382 × 10⁸
Jupiter  7.7834082 × 10⁸
Saturn   1.4266664 × 10⁹
Uranus   2.8706582 × 10⁹
Neptune  4.4983964 × 10⁹
'''),
      );
    });

    test('Outline table has rule line with right colors', () {
      final table = Table()
        ..insertColumn(header: 'Planet')
        ..insertColumn(
          header: 'Orbital Distance',
          alignment: TextAlignment.right,
        )
        ..insertRows(planets)
        ..headerStyle = FontStyle.bold
        ..borderColor = ConsoleColor.brightRed
        ..borderType = BorderType.outline;

      expect(
        table.toString(),
        equals('''
[91m╭──────────────────────────╮[m
[91m│ [m[1mPlanet [m [1mOrbital Distance[m[91m │[m
[91m│                          │[m
[91m│ [mMercury  5.7909227 × 10⁷[91m │[m
[91m│ [mVenus    1.0820948 × 10⁸[91m │[m
[91m│ [mEarth    1.4959826 × 10⁸[91m │[m
[91m│ [mMars     2.2794382 × 10⁸[91m │[m
[91m│ [mJupiter  7.7834082 × 10⁸[91m │[m
[91m│ [mSaturn   1.4266664 × 10⁹[91m │[m
[91m│ [mUranus   2.8706582 × 10⁹[91m │[m
[91m│ [mNeptune  4.4983964 × 10⁹[91m │[m
[91m╰──────────────────────────╯[m
'''),
      );
    });

    test('Can strip out ANSI formatting successfully', () {
      final table = Table()
        ..insertColumn(header: 'Number', alignment: TextAlignment.right)
        ..insertColumn(header: 'Presidency')
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents)
        ..borderStyle = BorderStyle.square
        ..borderColor = ConsoleColor.brightBlue
        ..borderType = BorderType.vertical
        ..headerStyle = FontStyle.bold;

      expect(
        table.render(plainText: true),
        equals('''
┌────────┬────────────────────────────────┬───────────────────┬───────────────────────┐
│ Number │ Presidency                     │ President         │ Party                 │
│        │                                │                   │                       │
│      1 │ April 30, 1789 - March 4, 1797 │ George Washington │ unaffiliated          │
│      2 │ March 4, 1797 - March 4, 1801  │ John Adams        │ Federalist            │
│      3 │ March 4, 1801 - March 4, 1809  │ Thomas Jefferson  │ Democratic-Republican │
│      4 │ March 4, 1809 - March 4, 1817  │ James Madison     │ Democratic-Republican │
│      5 │ March 4, 1817 - March 4, 1825  │ James Monroe      │ Democratic-Republican │
└────────┴────────────────────────────────┴───────────────────┴───────────────────────┘
'''),
      );
    });

    test('Color header rows', () {
      final table = Table()
        ..borderColor = ConsoleColor.brightRed
        ..headerColor = ConsoleColor.brightBlue
        ..insertColumn(header: '#')
        ..insertColumn(header: 'Presidency')
        ..insertColumn(header: 'President')
        ..insertColumn(header: 'Party')
        ..insertRows(earlyPresidents)
        ..deleteColumn(1);
      expect(
        table.toString(),
        equals('''
[91m╭───┬───────────────────┬───────────────────────╮[m
[91m│ [m[94m#[m[91m │ [m[94mPresident        [m[91m │ [m[94mParty                [m[91m │[m
[91m├───┼───────────────────┼───────────────────────┤[m
[91m│ [m1[91m │ [mGeorge Washington[91m │ [munaffiliated         [91m │[m
[91m│ [m2[91m │ [mJohn Adams       [91m │ [mFederalist           [91m │[m
[91m│ [m3[91m │ [mThomas Jefferson [91m │ [mDemocratic-Republican[91m │[m
[91m│ [m4[91m │ [mJames Madison    [91m │ [mDemocratic-Republican[91m │[m
[91m│ [m5[91m │ [mJames Monroe     [91m │ [mDemocratic-Republican[91m │[m
[91m╰───┴───────────────────┴───────────────────────╯[m
'''),
      );
    });

    test('Table with EastAsian characters', () {
      final table = Table()
        ..insertRows([
          ['US', 'America', 'English', '🇺🇸'],
          ['CN', '中国', '简体中文', '🇨🇳'],
          ['JP', 'にっぽん‌', 'にほんご', '🇯🇵'],
          ['KR', '대한민국', '한국어', '🇰🇷'],
        ]);
      expect(
        table.toString(),
        equals('''
╭────┬──────────┬──────────┬────╮
│ US │ America  │ English  │ 🇺🇸 │
│ CN │ 中国     │ 简体中文 │ 🇨🇳 │
│ JP │ にっぽん‌ │ にほんご │ 🇯🇵 │
│ KR │ 대한민국 │ 한국어   │ 🇰🇷 │
╰────┴──────────┴──────────┴────╯
'''),
      );
    });
  });
}
