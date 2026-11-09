import 'package:flutter_test/flutter_test.dart';
import 'package:verdadero_ingeniero/data/events.dart';
import 'package:verdadero_ingeniero/data/models.dart';
import 'package:verdadero_ingeniero/data/ranks.dart';

void main() {
  group('Lectura de respuestas numéricas', () {
    test('coma y punto decimal', () {
      expect(parseUserNumber('3,14'), closeTo(3.14, 1e-9));
      expect(parseUserNumber('3.14'), closeTo(3.14, 1e-9));
    });
    test('miles, signo y notación científica', () {
      expect(parseUserNumber('1.234,5'), closeTo(1234.5, 1e-9));
      expect(parseUserNumber('400 000'), closeTo(400000, 1e-9));
      expect(parseUserNumber('−14'), closeTo(-14, 1e-9));
      expect(parseUserNumber('4e5'), closeTo(400000, 1e-9));
      expect(parseUserNumber('4·10^5'), closeTo(400000, 1e-9));
    });
    test('entradas no válidas', () {
      expect(parseUserNumber(''), isNull);
      expect(parseUserNumber('abc'), isNull);
    });
  });

  test('formato de números en español', () {
    expect(fmtNum(25), '25');
    expect(fmtNum(206.84), '206,84');
    expect(fmtNum(0.44721), '0,4472');
    expect(fmtNum(31000000), '31000000');
    expect(fmtNum(3.1e7 + 0.5), '3,100·10^7');
  });

  test('rangos por experiencia', () {
    expect(rankFor(0).level, 1);
    expect(rankFor(0).title, 'Aprendiz');
    expect(rankFor(80).level, 2);
    expect(rankFor(1280).level, 5);
    expect(rankFor(1280).title, 'Técnico');
    expect(rankFor(170000).title, 'Verdadero Ingeniero');
    expect(rankFor(200).progress, closeTo(0.5, 1e-9));
  });

  test('modelos: resultado de examen', () {
    final r = ExamResult.fromJson({
      'exam_id': 'x',
      'mode': 'daily',
      'day_number': 1,
      'score': 90.0,
      'passed': true,
      'correct': 9,
      'total': 10,
      'xp_earned': 220,
      'level_change': 1,
      'day_advanced': true,
      'profile': {'id': 'u', 'current_day': 2, 'current_level': 2, 'xp': 220},
      'results': [
        {
          'question_id': 'q',
          'qtype': 'numeric',
          'prompt_md': 'p',
          'answer_value': 25,
          'tolerance_pct': 1,
          'explanation_md': 'e',
          'your_answer': {'question_id': 'q', 'value': 25},
          'is_correct': true,
        }
      ],
    });
    expect(r.passed, isTrue);
    expect(r.profile.currentDay, 2);
    expect(r.results.single.yourValue, 25);
  });
}
