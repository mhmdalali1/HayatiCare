class MedicalTestInfo {
  final String name;
  final String code;
  final String range;
  final String role;

  const MedicalTestInfo({
    required this.name,
    required this.code,
    required this.range,
    required this.role,
  });
}

const Map<String, MedicalTestInfo> _testByCode = {
  'GLU': MedicalTestInfo(
    name: 'Blood Glucose',
    code: 'GLU',
    range: '3.9 – 5.5 mmol/L (fasting)',
    role: 'Measures blood sugar level. Used to screen for diabetes and monitor glucose control.',
  ),
  'HGB': MedicalTestInfo(
    name: 'Hemoglobin',
    code: 'HGB',
    range: '12.0 – 17.5 g/dL',
    role: 'Carries oxygen from the lungs to the rest of the body. Low levels may indicate anemia.',
  ),
  'CHOL': MedicalTestInfo(
    name: 'Total Cholesterol',
    code: 'CHOL',
    range: '0.0 – 5.2 mmol/L (desirable)',
    role: 'Measures total cholesterol in the blood. Used to assess cardiovascular risk.',
  ),
  'WBC': MedicalTestInfo(
    name: 'White Blood Cells',
    code: 'WBC',
    range: '4.0 – 11.0 × 10⁹/L',
    role: 'Helps fight infections. High levels may indicate infection or inflammation.',
  ),
  'BP': MedicalTestInfo(
    name: 'Blood Pressure',
    code: 'BP',
    range: 'Systolic < 120 mmHg / Diastolic < 80 mmHg (normal)',
    role: 'Measures the force of blood against artery walls. Used to evaluate cardiovascular health.',
  ),
  'PLT': MedicalTestInfo(
    name: 'Platelets',
    code: 'PLT',
    range: '150 – 450 × 10⁹/L',
    role: 'Helps blood clot. Low levels may increase bleeding risk.',
  ),
  'NA': MedicalTestInfo(
    name: 'Sodium',
    code: 'NA',
    range: '135 – 145 mmol/L',
    role: 'Regulates fluid balance and nerve function. Essential for hydration and blood pressure control.',
  ),
  'K': MedicalTestInfo(
    name: 'Potassium',
    code: 'K',
    range: '3.5 – 5.0 mmol/L',
    role: 'Essential for muscle contraction and heart rhythm. Imbalance can affect cardiac function.',
  ),
  'CRE': MedicalTestInfo(
    name: 'Creatinine',
    code: 'CRE',
    range: '0.6 – 1.3 mg/dL',
    role: 'Measures kidney function. High levels may indicate impaired kidney function.',
  ),
  'ALT': MedicalTestInfo(
    name: 'ALT (Alanine Aminotransferase)',
    code: 'ALT',
    range: '7 – 56 U/L',
    role: 'Liver enzyme. Elevated levels may indicate liver inflammation or damage.',
  ),
  'AST': MedicalTestInfo(
    name: 'AST (Aspartate Aminotransferase)',
    code: 'AST',
    range: '10 – 40 U/L',
    role: 'Liver enzyme. Often measured with ALT to assess liver health.',
  ),
  'SPO2': MedicalTestInfo(
    name: 'Oxygen Saturation',
    code: 'SPO2',
    range: '95 – 100%',
    role: 'Measures oxygen level in the blood. Low levels may indicate respiratory issues.',
  ),
  'TEMP': MedicalTestInfo(
    name: 'Temperature',
    code: 'TEMP',
    range: '36.1 – 37.2 °C',
    role: 'Measures body temperature. Used to detect fever or hypothermia.',
  ),
};

final Map<String, String> _nameToCode = {
  'white blood cells': 'WBC',
  'white blood cell': 'WBC',
  'blood glucose': 'GLU',
  'blood pressure': 'BP',
  'total cholesterol': 'CHOL',
  'oxygen saturation': 'SPO2',
  'alanine aminotransferase': 'ALT',
  'aspartate aminotransferase': 'AST',
  'hemoglobin': 'HGB',
  'haemoglobin': 'HGB',
  'cholesterol': 'CHOL',
  'creatinine': 'CRE',
  'potassium': 'K',
  'platelets': 'PLT',
  'platelet': 'PLT',
  'glucose': 'GLU',
  'sodium': 'NA',
  'oxygen': 'SPO2',
  'saturation': 'SPO2',
  'temperature': 'TEMP',
  'sugar': 'GLU',
  'fever': 'TEMP',
  'hb': 'HGB',
  'temp': 'TEMP',
};

String getTestCode(String input) {
  final cleaned = input.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  final words = cleaned.split(RegExp(r'\s+'));

  for (final word in words) {
    if (word.isEmpty) continue;
    final upper = word.toUpperCase();
    if (_testByCode.containsKey(upper)) {
      return upper;
    }
  }

  for (final entry in _nameToCode.entries) {
    if (cleaned.contains(entry.key)) {
      return entry.value;
    }
  }

  return '';
}

bool _isGreeting(String msg) {
  final trimmed = msg.trim();
  const greetings = ['hi', 'hello', 'hey', 'good morning', 'good evening'];
  for (final g in greetings) {
    if (trimmed == g || trimmed.startsWith('$g ')) {
      return true;
    }
  }
  return false;
}

bool _asksForRange(String msg) {
  return msg.contains('range') ||
      msg.contains('normal range') ||
      msg.contains('level') ||
      msg.contains('normal');
}

bool _asksForRole(String msg) {
  return msg.contains('role') ||
      msg.contains('function') ||
      msg.contains('used for') ||
      msg.contains('what does') ||
      msg.contains('do for') ||
      msg.contains('meaning');
}

bool _isAllowedQuery(String msg) {
  const forbidden = [
    'diagnosis',
    'diagnose',
    'symptom',
    'treatment',
    'treat',
    'cure',
    'medicine',
    'medication',
    'drug',
    'prescription',
    'dosage',
    'dangerous',
    'what should i do',
    'what to do',
    'how can i',
    'how do i',
    'my result',
    'my value',
    'my test',
    'is my',
    'am i',
    'my level',
    'disease',
    'emergency',
    'decrease',
    'lower',
    'reduce',
    'increase',
    'raise',
    'fix',
    'manage',
    'improve',
    'diet',
    'food',
    'eat',
  ];
  for (final word in forbidden) {
    if (msg.contains(word)) return false;
  }
  return true;
}

String getAiResponse(String query) {
  final msg = query.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

  if (_isGreeting(msg)) {
    return 'Hello! I can help you with normal ranges and roles of medical test results.';
  }

  if (!_isAllowedQuery(msg)) {
    return 'Please consult your doctor for this matter.';
  }

  final code = getTestCode(msg);
  if (code.isEmpty) {
    return 'Test not recognized. Please use a valid medical test name.';
  }

  final info = _testByCode[code]!;
  final asksRange = _asksForRange(msg);
  final asksRole = _asksForRole(msg);

  if (asksRange && !asksRole) {
    return 'Normal range for ${info.name} ($code): ${info.range}';
  }

  if (asksRole) {
    return 'Role of ${info.name} ($code): ${info.role}';
  }

  if (msg.contains('what is') || msg.contains('tell me about')) {
    return 'Role of ${info.name} ($code): ${info.role}';
  }

  return 'I can tell you the normal range or role of ${info.name}. Please ask which one you want.';
}
