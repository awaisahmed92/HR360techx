import 'package:flutter/material.dart';

import '../widgets/hr_record_kit.dart';

const _jobFields = ['-', 'Information Technology', 'Human Resource', 'Accounts & Finance', 'IT & Development', 'Ui/Ux reviewer'];
const _jobTypes = ['Permanent', 'Contract', 'Project Based', 'Intern'];
const _jobFor = ['Career Portal', 'Internal Job Post', 'Both'];
const _yesNo = ['Yes', 'No'];
const _ages = ['-', ...['16','18','21','25','30','35','40','45','50','55','60']];
const _countries = ['United States', 'Pakistan', 'United Arab Emirates', 'United Kingdom', 'Canada', 'India', 'Saudi Arabia', 'Germany', 'Australia'];
const _fieldTypes = ['Text Box', 'List Box', 'Text Area', 'Date', 'Time', 'Number'];

Map<String, dynamic> _details(Map<String, dynamic>? row) {
  final d = row?['details'];
  return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
}

class JobRequestForm extends StatefulWidget {
  const JobRequestForm({super.key, this.row, required this.onSave});
  final Map<String, dynamic>? row;
  final Future<void> Function(Map<String, dynamic> body) onSave;
  @override
  State<JobRequestForm> createState() => _JobRequestFormState();
}

class _JobRequestFormState extends State<JobRequestForm> {
  late final title = TextEditingController(text: '${widget.row?['job_title'] ?? ''}');
  late final positions = TextEditingController(text: '${widget.row?['vacancies'] ?? 1}');
  late final open = TextEditingController(text: '${widget.row?['opening_date'] ?? ''}');
  late final close = TextEditingController(text: '${widget.row?['closing_date'] ?? ''}');
  late final salaryStart = TextEditingController(text: '${widget.row?['salary_min'] ?? ''}');
  late final salaryEnd = TextEditingController(text: '${widget.row?['salary_max'] ?? ''}');
  late final qual = TextEditingController(text: '${widget.row?['qualification'] ?? ''}');
  late final exp = TextEditingController(text: '${widget.row?['experience'] ?? ''}');
  late final desc = TextEditingController(text: '${widget.row?['description'] ?? ''}');
  late final notes = TextEditingController(text: '${widget.row?['notes'] ?? ''}');
  late String jobType = '${widget.row?['job_type'] ?? 'Permanent'}';
  late String ageStart = '${_details(widget.row)['age_start'] ?? '-'}';
  late String ageEnd = '${_details(widget.row)['age_end'] ?? '-'}';

  @override
  Widget build(BuildContext context) {
    return HrRecordForm(
      title: widget.row == null ? 'Add New Job Request' : 'Edit Job Request',
      onSave: () {
        widget.onSave({
          'job_title': title.text.trim(),
          'job_type': jobType,
          'vacancies': int.tryParse(positions.text) ?? 1,
          'opening_date': open.text.trim().isEmpty ? null : open.text.trim(),
          'closing_date': close.text.trim().isEmpty ? null : close.text.trim(),
          'salary_min': num.tryParse(salaryStart.text),
          'salary_max': num.tryParse(salaryEnd.text),
          'qualification': qual.text.trim(),
          'experience': exp.text.trim(),
          'description': desc.text.trim(),
          'notes': notes.text.trim(),
          'details': {'age_start': ageStart, 'age_end': ageEnd},
        });
      },
      children: [
        const HrFormSection('Job Request Information'),
        HrField(label: 'Job Title:', required: true, child: HrWaInput(controller: title, hint: 'Job Title')),
        HrField(label: 'Job Type:', child: HrWaSelect(value: jobType, items: _jobTypes, onChanged: (v) => setState(() => jobType = v ?? jobType))),
        HrField(label: 'Job Post Opening Date:', child: HrWaDate(controller: open)),
        HrField(label: 'Job Post Closing Date:', child: HrWaDate(controller: close)),
        HrField(label: 'Number of Positions:', required: true, child: HrWaInput(controller: positions)),
        HrField(label: 'Candidate Age Range (Start):', child: HrWaSelect(value: ageStart, items: _ages, onChanged: (v) => setState(() => ageStart = v ?? '-'))),
        HrField(label: 'Candidate Age Range (End):', child: HrWaSelect(value: ageEnd, items: _ages, onChanged: (v) => setState(() => ageEnd = v ?? '-'))),
        HrField(label: 'Salary Start Range:', child: HrWaInput(controller: salaryStart)),
        HrField(label: 'Salary End Range:', child: HrWaInput(controller: salaryEnd)),
        const HrFormSection('Candidate Qualification'),
        HrField(label: 'Candidate Qualification:', child: HrRichNote(controller: qual)),
        const HrFormSection('Candidate Experience'),
        HrField(label: 'Candidate Experience:', required: true, child: HrRichNote(controller: exp)),
        const HrFormSection('Job Post Description'),
        HrField(label: 'Job Post Description:', child: HrRichNote(controller: desc)),
        const HrFormSection('Additional Information'),
        HrField(label: 'Notes:', child: HrRichNote(controller: notes)),
      ],
    );
  }
}

class JobPostForm extends StatefulWidget {
  const JobPostForm({super.key, this.row, this.internal = false, required this.onSave});
  final Map<String, dynamic>? row;
  final bool internal;
  final Future<void> Function(Map<String, dynamic> body) onSave;
  @override
  State<JobPostForm> createState() => _JobPostFormState();
}

class _JobPostFormState extends State<JobPostForm> {
  late final d = _details(widget.row);
  late final title = TextEditingController(text: '${widget.row?['title'] ?? ''}');
  late final positions = TextEditingController(text: '${widget.row?['vacancies'] ?? 1}');
  late final open = TextEditingController(text: '${widget.row?['opening_date'] ?? ''}');
  late final close = TextEditingController(text: '${widget.row?['closing_date'] ?? ''}');
  late final email = TextEditingController(text: '${d['email'] ?? ''}');
  late final city = TextEditingController(text: '${d['city'] ?? ''}');
  late final province = TextEditingController(text: '${d['province'] ?? ''}');
  late final postal = TextEditingController(text: '${d['postal'] ?? ''}');
  late final salaryStart = TextEditingController(text: '${d['salary_start'] ?? ''}');
  late final salaryEnd = TextEditingController(text: '${d['salary_end'] ?? ''}');
  late final qual = TextEditingController(text: '${widget.row?['qualification'] ?? ''}');
  late final exp = TextEditingController(text: '${widget.row?['experience'] ?? ''}');
  late final desc = TextEditingController(text: '${widget.row?['description'] ?? ''}');
  late final notes = TextEditingController(text: '${d['notes'] ?? ''}');
  late final hiring = TextEditingController(text: '${d['hiring_manager'] ?? ''}');
  late final contributors = TextEditingController(text: '${d['contributors'] ?? ''}');
  late final interviewers = TextEditingController(text: '${d['interviewers'] ?? ''}');
  late String field = '${d['job_field'] ?? '-'}';
  late String jobType = _jobTypes.contains('${widget.row?['job_type']}') ? '${widget.row?['job_type']}' : 'Permanent';
  late String jobFor = _jobFor[(widget.row?['job_for'] as num?)?.toInt().clamp(0, 2) ?? (widget.internal ? 1 : 0)];
  late String publish = (widget.row?['publish_portal'] == false) ? 'No' : 'Yes';
  late String resume = '${d['must_resume'] ?? 'No'}';
  late String company = '${d['company'] ?? 'All Companies'}';
  late String division = '${d['division'] ?? 'All Divisions'}';
  late String station = '${d['station'] ?? 'All Stations'}';
  late String department = '${d['department'] ?? 'All Departments'}';
  late String country = '${d['country'] ?? 'United States'}';
  late String ageStart = '${d['age_start'] ?? '-'}';
  late String ageEnd = '${d['age_end'] ?? '-'}';
  late bool restrictAge = d['restrict_age'] == true;
  late final List<Map<String, String>> questions = _seedQuestions(d['questions']);

  static List<Map<String, String>> _seedQuestions(dynamic raw) {
    final out = <Map<String, String>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          out.add({
            'type': '${item['type'] ?? 'Text Box'}',
            'name': '${item['name'] ?? ''}',
            'category': '${item['category'] ?? ''}',
            'options': '${item['options'] ?? ''}',
            'mandatory': '${item['mandatory'] ?? 'No'}',
            'order': '${item['order'] ?? '0'}',
            'hidden': '${item['hidden'] ?? 'No'}',
          });
        }
      }
    }
    while (out.length < 5) {
      out.add({'type': 'Text Box', 'name': '', 'category': '', 'options': '', 'mandatory': 'No', 'order': '${out.length}', 'hidden': 'No'});
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return HrRecordForm(
      title: widget.row == null ? 'Add New Job Post' : 'Edit Job Post',
      onSave: _save,
      children: [
        const HrFormSection('Job Post Information'),
        HrField(label: 'Job Title:', required: true, child: HrWaInput(controller: title, hint: 'Job Title')),
        HrField(label: 'Job Field:', child: HrWaSelect(value: field, items: _jobFields, onChanged: (v) => setState(() => field = v ?? field))),
        HrField(label: 'Job Type:', child: HrWaSelect(value: jobType, items: _jobTypes, onChanged: (v) => setState(() => jobType = v ?? jobType))),
        HrField(label: 'Job For:', child: HrWaSelect(value: jobFor, items: _jobFor, onChanged: (v) => setState(() => jobFor = v ?? jobFor))),
        HrField(label: 'Job Post Opening Date:', child: HrWaDate(controller: open)),
        HrField(label: 'Job Post Closing Date:', child: HrWaDate(controller: close)),
        HrField(label: 'Number of Positions:', required: true, child: HrWaInput(controller: positions)),
        HrField(label: 'Publish in Jobs Portal:', child: HrWaSelect(value: publish, items: _yesNo, onChanged: (v) => setState(() => publish = v ?? 'Yes'))),
        HrField(label: 'Must Upload Resume:', child: HrWaSelect(value: resume, items: const ['No', 'Yes'], onChanged: (v) => setState(() => resume = v ?? 'No'))),
        const HrFormSection('Job Post Details'),
        HrField(label: 'Company:', child: HrWaSelect(value: company, items: const ['All Companies'], onChanged: (v) => setState(() => company = v ?? company))),
        HrField(label: 'Division:', child: HrWaSelect(value: division, items: const ['All Divisions'], onChanged: (v) => setState(() => division = v ?? division))),
        HrField(label: 'Station:', child: HrWaSelect(value: station, items: const ['All Stations'], onChanged: (v) => setState(() => station = v ?? station))),
        HrField(label: 'Department:', child: HrWaSelect(value: department, items: const ['All Departments'], onChanged: (v) => setState(() => department = v ?? department))),
        HrField(label: 'Job Post Email Address:', child: HrWaInput(controller: email)),
        const HrFormSection('Recruiters'),
        HrField(label: 'Hiring Manager:', child: HrWaInput(controller: hiring, hint: 'Employee name')),
        HrField(label: 'Contributors:', child: HrWaInput(controller: contributors, hint: 'Employee names')),
        HrField(label: 'Interviewers:', child: HrWaInput(controller: interviewers, hint: 'Employee names')),
        const HrFormSection('Job Location'),
        HrField(label: 'City:', child: HrWaInput(controller: city)),
        HrField(label: 'Province:', child: HrWaInput(controller: province)),
        HrField(label: 'Postal Code:', child: HrWaInput(controller: postal)),
        HrField(label: 'Country:', child: HrWaSelect(value: country, items: _countries, onChanged: (v) => setState(() => country = v ?? country))),
        const HrFormSection('Candidate Age Range'),
        HrField(label: 'Candidate Age Range (Start):', child: HrWaSelect(value: ageStart, items: _ages, onChanged: (v) => setState(() => ageStart = v ?? '-'))),
        HrField(label: 'Candidate Age Range (End):', child: HrWaSelect(value: ageEnd, items: _ages, onChanged: (v) => setState(() => ageEnd = v ?? '-'))),
        HrField(label: 'Restrict Candidate Age Range:', child: HrWaSwitch(value: restrictAge, onChanged: (v) => setState(() => restrictAge = v))),
        const HrFormSection('Salary'),
        HrField(label: 'Salary Start Range:', child: HrWaInput(controller: salaryStart)),
        HrField(label: 'Salary End Range:', child: HrWaInput(controller: salaryEnd)),
        const HrFormSection('Candidate Qualification'),
        HrField(label: 'Candidate Qualification:', child: HrRichNote(controller: qual)),
        const HrFormSection('Candidate Experience'),
        HrField(label: 'Candidate Experience:', required: true, child: HrRichNote(controller: exp)),
        const HrFormSection('Job Post Description'),
        HrField(label: 'Job Post Description:', child: HrRichNote(controller: desc)),
        const HrFormSection('Job Post Additional Questions'),
        _questionTable(),
        TextButton.icon(
          onPressed: () => setState(() => questions.add({'type': 'Text Box', 'name': '', 'category': '', 'options': '', 'mandatory': 'No', 'order': '${questions.length}', 'hidden': 'No'})),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add New Row'),
        ),
        const HrFormSection('Additional Information'),
        HrField(label: 'Notes:', child: HrRichNote(controller: notes)),
      ],
    );
  }

  Widget _questionTable() {
    Widget box(String key, int i, double width) {
      return SizedBox(
        width: width,
        child: TextFormField(
          initialValue: questions[i][key],
          onChanged: (v) => questions[i][key] = v,
          decoration: hrWaDecoration(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: kRecPurple,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: const Row(
              children: [
                SizedBox(width: 28, child: Text('#', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 140, child: Text('Field Type', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 160, child: Text('Field Name', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 120, child: Text('Category', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 140, child: Text('Options', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 110, child: Text('Mandatory', style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
          ),
          for (var i = 0; i < questions.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('${i + 1}')),
                  SizedBox(
                    width: 140,
                    child: HrWaSelect(
                      value: questions[i]['type'],
                      items: _fieldTypes,
                      onChanged: (v) => setState(() => questions[i]['type'] = v ?? 'Text Box'),
                    ),
                  ),
                  box('name', i, 160),
                  box('category', i, 120),
                  box('options', i, 140),
                  SizedBox(
                    width: 110,
                    child: HrWaSelect(
                      value: questions[i]['mandatory'],
                      items: const ['No', 'Yes'],
                      onChanged: (v) => setState(() => questions[i]['mandatory'] = v ?? 'No'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _save() {
    final forIndex = _jobFor.indexOf(jobFor).clamp(0, 2);
    widget.onSave({
      'title': title.text.trim(),
      'job_type': jobType,
      'job_for': forIndex,
      'vacancies': int.tryParse(positions.text) ?? 1,
      'publish_portal': publish == 'Yes',
      'opening_date': open.text.trim().isEmpty ? null : open.text.trim(),
      'closing_date': close.text.trim().isEmpty ? null : close.text.trim(),
      'qualification': qual.text.trim(),
      'experience': exp.text.trim(),
      'description': desc.text.trim(),
      'locations': [city.text, province.text, country].where((s) => s.trim().isNotEmpty).join(', '),
      'status': 1,
      'details': {
        'job_field': field,
        'company': company,
        'division': division,
        'station': station,
        'department': department,
        'email': email.text.trim(),
        'must_resume': resume,
        'city': city.text.trim(),
        'province': province.text.trim(),
        'postal': postal.text.trim(),
        'country': country,
        'age_start': ageStart,
        'age_end': ageEnd,
        'restrict_age': restrictAge,
        'salary_start': salaryStart.text.trim(),
        'salary_end': salaryEnd.text.trim(),
        'hiring_manager': hiring.text.trim(),
        'contributors': contributors.text.trim(),
        'interviewers': interviewers.text.trim(),
        'notes': notes.text.trim(),
        'questions': questions,
      },
    });
  }
}

class JobCandidateForm extends StatefulWidget {
  const JobCandidateForm({super.key, required this.posts, required this.onSave});
  final List<Map<String, dynamic>> posts;
  final Future<void> Function(Map<String, dynamic> body) onSave;
  @override
  State<JobCandidateForm> createState() => _JobCandidateFormState();
}

class _JobCandidateFormState extends State<JobCandidateForm> {
  final preferred = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final govId = TextEditingController();
  String? postTitle;
  String field = 'Information Technology';

  @override
  Widget build(BuildContext context) {
    final titles = widget.posts.map((p) => '${p['title']}').toList();
    return HrRecordForm(
      title: 'Add New Job Candidate',
      onSave: () {
        final post = widget.posts.cast<Map<String, dynamic>?>().firstWhere(
              (p) => '${p?['title']}' == postTitle,
              orElse: () => null,
            );
        widget.onSave({
          'name': '${preferred.text.trim()} ${last.text.trim()}'.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'cnic': govId.text.trim(),
          'job_id': post?['legacy_job_id'],
          'qualification': field,
          'status': 0,
        });
      },
      children: [
        const HrFormSection('Job Post'),
        HrField(
          label: 'Job Post:',
          child: HrWaSelect(
            value: postTitle,
            hint: '-',
            items: titles,
            onChanged: (v) => setState(() => postTitle = v),
          ),
        ),
        const HrFormSection('Candidate Information'),
        HrField(label: 'Job Field:', child: HrWaSelect(value: field, items: _jobFields.where((e) => e != '-').toList(), onChanged: (v) => setState(() => field = v ?? field))),
        HrField(label: 'Preferred Name:', child: HrWaInput(controller: preferred, hint: 'Preferred Name')),
        HrField(label: 'Last Name:', child: HrWaInput(controller: last, hint: 'Last Name')),
        HrField(label: 'Email Address:', child: HrWaInput(controller: email, hint: 'Email')),
        HrField(label: 'Mobile Number:', child: HrWaInput(controller: phone, hint: 'Mobile')),
        HrField(label: 'Government Id:', child: HrWaInput(controller: govId, hint: 'Government Id')),
      ],
    );
  }
}

class JobTestForm extends StatefulWidget {
  const JobTestForm({super.key, required this.onSave});
  final Future<void> Function(Map<String, dynamic> body) onSave;
  @override
  State<JobTestForm> createState() => _JobTestFormState();
}

class _JobTestFormState extends State<JobTestForm> {
  final title = TextEditingController();
  final description = TextEditingController();
  final questions = List.generate(5, (i) => {'question': TextEditingController(), 'answer': TextEditingController(), 'score': '1'});

  @override
  Widget build(BuildContext context) {
    return HrRecordForm(
      title: 'Add New Job Test',
      onSave: () {
        widget.onSave({
          'title': title.text.trim(),
          'description': description.text.trim(),
          'pass_score': 50,
          'questions': [
            for (final q in questions)
              if (q['question'] is TextEditingController && (q['question'] as TextEditingController).text.trim().isNotEmpty)
                {
                  'question': (q['question'] as TextEditingController).text.trim(),
                  'correct_answer': (q['answer'] as TextEditingController).text.trim(),
                  'points': num.tryParse('${q['score']}') ?? 1,
                  'options': <String>[],
                },
          ],
        });
      },
      children: [
        const HrFormSection('Job Test Information'),
        HrField(label: 'Test Title:', required: true, child: HrWaInput(controller: title, hint: 'Test Title')),
        const HrFormSection('Job Test Questions'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(kRecPurple),
            headingTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Question')),
              DataColumn(label: Text('Correct Answer')),
              DataColumn(label: Text('Score')),
            ],
            rows: [
              for (var i = 0; i < questions.length; i++)
                DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(SizedBox(width: 220, child: HrWaInput(controller: questions[i]['question'] as TextEditingController))),
                  DataCell(SizedBox(width: 160, child: HrWaInput(controller: questions[i]['answer'] as TextEditingController))),
                  DataCell(Text('${questions[i]['score']}')),
                ]),
            ],
          ),
        ),
        const HrFormSection('Job Test Description'),
        HrField(label: 'Description:', child: HrRichNote(controller: description)),
      ],
    );
  }
}
