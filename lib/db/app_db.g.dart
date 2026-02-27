// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $WorkoutDaysTable extends WorkoutDays
    with TableInfo<$WorkoutDaysTable, WorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutDateMeta =
      const VerificationMeta('workoutDate');
  @override
  late final GeneratedColumn<String> workoutDate = GeneratedColumn<String>(
      'workout_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, workoutDate, createdAt, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_days';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_date')) {
      context.handle(
          _workoutDateMeta,
          workoutDate.isAcceptableOrUnknown(
              data['workout_date']!, _workoutDateMeta));
    } else if (isInserting) {
      context.missing(_workoutDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $WorkoutDaysTable createAlias(String alias) {
    return $WorkoutDaysTable(attachedDatabase, alias);
  }
}

class WorkoutDay extends DataClass implements Insertable<WorkoutDay> {
  final String id;
  final String workoutDate;
  final int createdAt;
  final String? notes;
  const WorkoutDay(
      {required this.id,
      required this.workoutDate,
      required this.createdAt,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_date'] = Variable<String>(workoutDate);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaysCompanion(
      id: Value(id),
      workoutDate: Value(workoutDate),
      createdAt: Value(createdAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDay(
      id: serializer.fromJson<String>(json['id']),
      workoutDate: serializer.fromJson<String>(json['workoutDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDate': serializer.toJson<String>(workoutDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutDay copyWith(
          {String? id,
          String? workoutDate,
          int? createdAt,
          Value<String?> notes = const Value.absent()}) =>
      WorkoutDay(
        id: id ?? this.id,
        workoutDate: workoutDate ?? this.workoutDate,
        createdAt: createdAt ?? this.createdAt,
        notes: notes.present ? notes.value : this.notes,
      );
  WorkoutDay copyWithCompanion(WorkoutDaysCompanion data) {
    return WorkoutDay(
      id: data.id.present ? data.id.value : this.id,
      workoutDate:
          data.workoutDate.present ? data.workoutDate.value : this.workoutDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDay(')
          ..write('id: $id, ')
          ..write('workoutDate: $workoutDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workoutDate, createdAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDay &&
          other.id == this.id &&
          other.workoutDate == this.workoutDate &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes);
}

class WorkoutDaysCompanion extends UpdateCompanion<WorkoutDay> {
  final Value<String> id;
  final Value<String> workoutDate;
  final Value<int> createdAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const WorkoutDaysCompanion({
    this.id = const Value.absent(),
    this.workoutDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutDaysCompanion.insert({
    required String id,
    required String workoutDate,
    required int createdAt,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutDate = Value(workoutDate),
        createdAt = Value(createdAt);
  static Insertable<WorkoutDay> custom({
    Expression<String>? id,
    Expression<String>? workoutDate,
    Expression<int>? createdAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDate != null) 'workout_date': workoutDate,
      if (createdAt != null) 'created_at': createdAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutDaysCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutDate,
      Value<int>? createdAt,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return WorkoutDaysCompanion(
      id: id ?? this.id,
      workoutDate: workoutDate ?? this.workoutDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDate.present) {
      map['workout_date'] = Variable<String>(workoutDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaysCompanion(')
          ..write('id: $id, ')
          ..write('workoutDate: $workoutDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActualStrengthSetsTable extends ActualStrengthSets
    with TableInfo<$ActualStrengthSetsTable, ActualStrengthSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActualStrengthSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutDayIdMeta =
      const VerificationMeta('workoutDayId');
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
      'workout_day_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _performedAtMeta =
      const VerificationMeta('performedAt');
  @override
  late final GeneratedColumn<int> performedAt = GeneratedColumn<int>(
      'performed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exerciseCanonicalMeta =
      const VerificationMeta('exerciseCanonical');
  @override
  late final GeneratedColumn<String> exerciseCanonical =
      GeneratedColumn<String>('exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prescribedExerciseCanonicalMeta =
      const VerificationMeta('prescribedExerciseCanonical');
  @override
  late final GeneratedColumn<String> prescribedExerciseCanonical =
      GeneratedColumn<String>(
          'prescribed_exercise_canonical', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _substitutionIdMeta =
      const VerificationMeta('substitutionId');
  @override
  late final GeneratedColumn<String> substitutionId = GeneratedColumn<String>(
      'substitution_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _setIndexMeta =
      const VerificationMeta('setIndex');
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
      'set_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
      'rir', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawSetStringMeta =
      const VerificationMeta('rawSetString');
  @override
  late final GeneratedColumn<String> rawSetString = GeneratedColumn<String>(
      'raw_set_string', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workoutDayId,
        planDayId,
        performedAt,
        exerciseCanonical,
        prescribedExerciseCanonical,
        substitutionId,
        setIndex,
        weight,
        reps,
        rir,
        unit,
        source,
        rawSetString,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actual_strength_sets';
  @override
  VerificationContext validateIntegrity(Insertable<ActualStrengthSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
          _workoutDayIdMeta,
          workoutDayId.isAcceptableOrUnknown(
              data['workout_day_id']!, _workoutDayIdMeta));
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    }
    if (data.containsKey('performed_at')) {
      context.handle(
          _performedAtMeta,
          performedAt.isAcceptableOrUnknown(
              data['performed_at']!, _performedAtMeta));
    }
    if (data.containsKey('exercise_canonical')) {
      context.handle(
          _exerciseCanonicalMeta,
          exerciseCanonical.isAcceptableOrUnknown(
              data['exercise_canonical']!, _exerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_exerciseCanonicalMeta);
    }
    if (data.containsKey('prescribed_exercise_canonical')) {
      context.handle(
          _prescribedExerciseCanonicalMeta,
          prescribedExerciseCanonical.isAcceptableOrUnknown(
              data['prescribed_exercise_canonical']!,
              _prescribedExerciseCanonicalMeta));
    }
    if (data.containsKey('substitution_id')) {
      context.handle(
          _substitutionIdMeta,
          substitutionId.isAcceptableOrUnknown(
              data['substitution_id']!, _substitutionIdMeta));
    }
    if (data.containsKey('set_index')) {
      context.handle(_setIndexMeta,
          setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta));
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('raw_set_string')) {
      context.handle(
          _rawSetStringMeta,
          rawSetString.isAcceptableOrUnknown(
              data['raw_set_string']!, _rawSetStringMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActualStrengthSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActualStrengthSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_day_id'])!,
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id']),
      performedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}performed_at']),
      exerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exercise_canonical'])!,
      prescribedExerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}prescribed_exercise_canonical']),
      substitutionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}substitution_id']),
      setIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_index'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rir']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      rawSetString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_set_string']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ActualStrengthSetsTable createAlias(String alias) {
    return $ActualStrengthSetsTable(attachedDatabase, alias);
  }
}

class ActualStrengthSet extends DataClass
    implements Insertable<ActualStrengthSet> {
  final String id;
  final String workoutDayId;
  final String? planDayId;
  final int? performedAt;
  final String exerciseCanonical;
  final String? prescribedExerciseCanonical;
  final String? substitutionId;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
  final String source;
  final String? rawSetString;
  final int createdAt;
  const ActualStrengthSet(
      {required this.id,
      required this.workoutDayId,
      this.planDayId,
      this.performedAt,
      required this.exerciseCanonical,
      this.prescribedExerciseCanonical,
      this.substitutionId,
      required this.setIndex,
      this.weight,
      this.reps,
      this.rir,
      required this.unit,
      required this.source,
      this.rawSetString,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<String>(planDayId);
    }
    if (!nullToAbsent || performedAt != null) {
      map['performed_at'] = Variable<int>(performedAt);
    }
    map['exercise_canonical'] = Variable<String>(exerciseCanonical);
    if (!nullToAbsent || prescribedExerciseCanonical != null) {
      map['prescribed_exercise_canonical'] =
          Variable<String>(prescribedExerciseCanonical);
    }
    if (!nullToAbsent || substitutionId != null) {
      map['substitution_id'] = Variable<String>(substitutionId);
    }
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['unit'] = Variable<String>(unit);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || rawSetString != null) {
      map['raw_set_string'] = Variable<String>(rawSetString);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ActualStrengthSetsCompanion toCompanion(bool nullToAbsent) {
    return ActualStrengthSetsCompanion(
      id: Value(id),
      workoutDayId: Value(workoutDayId),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      performedAt: performedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(performedAt),
      exerciseCanonical: Value(exerciseCanonical),
      prescribedExerciseCanonical:
          prescribedExerciseCanonical == null && nullToAbsent
              ? const Value.absent()
              : Value(prescribedExerciseCanonical),
      substitutionId: substitutionId == null && nullToAbsent
          ? const Value.absent()
          : Value(substitutionId),
      setIndex: Value(setIndex),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      unit: Value(unit),
      source: Value(source),
      rawSetString: rawSetString == null && nullToAbsent
          ? const Value.absent()
          : Value(rawSetString),
      createdAt: Value(createdAt),
    );
  }

  factory ActualStrengthSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActualStrengthSet(
      id: serializer.fromJson<String>(json['id']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      planDayId: serializer.fromJson<String?>(json['planDayId']),
      performedAt: serializer.fromJson<int?>(json['performedAt']),
      exerciseCanonical: serializer.fromJson<String>(json['exerciseCanonical']),
      prescribedExerciseCanonical:
          serializer.fromJson<String?>(json['prescribedExerciseCanonical']),
      substitutionId: serializer.fromJson<String?>(json['substitutionId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weight: serializer.fromJson<double?>(json['weight']),
      reps: serializer.fromJson<int?>(json['reps']),
      rir: serializer.fromJson<int?>(json['rir']),
      unit: serializer.fromJson<String>(json['unit']),
      source: serializer.fromJson<String>(json['source']),
      rawSetString: serializer.fromJson<String?>(json['rawSetString']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'planDayId': serializer.toJson<String?>(planDayId),
      'performedAt': serializer.toJson<int?>(performedAt),
      'exerciseCanonical': serializer.toJson<String>(exerciseCanonical),
      'prescribedExerciseCanonical':
          serializer.toJson<String?>(prescribedExerciseCanonical),
      'substitutionId': serializer.toJson<String?>(substitutionId),
      'setIndex': serializer.toJson<int>(setIndex),
      'weight': serializer.toJson<double?>(weight),
      'reps': serializer.toJson<int?>(reps),
      'rir': serializer.toJson<int?>(rir),
      'unit': serializer.toJson<String>(unit),
      'source': serializer.toJson<String>(source),
      'rawSetString': serializer.toJson<String?>(rawSetString),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ActualStrengthSet copyWith(
          {String? id,
          String? workoutDayId,
          Value<String?> planDayId = const Value.absent(),
          Value<int?> performedAt = const Value.absent(),
          String? exerciseCanonical,
          Value<String?> prescribedExerciseCanonical = const Value.absent(),
          Value<String?> substitutionId = const Value.absent(),
          int? setIndex,
          Value<double?> weight = const Value.absent(),
          Value<int?> reps = const Value.absent(),
          Value<int?> rir = const Value.absent(),
          String? unit,
          String? source,
          Value<String?> rawSetString = const Value.absent(),
          int? createdAt}) =>
      ActualStrengthSet(
        id: id ?? this.id,
        workoutDayId: workoutDayId ?? this.workoutDayId,
        planDayId: planDayId.present ? planDayId.value : this.planDayId,
        performedAt: performedAt.present ? performedAt.value : this.performedAt,
        exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
        prescribedExerciseCanonical: prescribedExerciseCanonical.present
            ? prescribedExerciseCanonical.value
            : this.prescribedExerciseCanonical,
        substitutionId:
            substitutionId.present ? substitutionId.value : this.substitutionId,
        setIndex: setIndex ?? this.setIndex,
        weight: weight.present ? weight.value : this.weight,
        reps: reps.present ? reps.value : this.reps,
        rir: rir.present ? rir.value : this.rir,
        unit: unit ?? this.unit,
        source: source ?? this.source,
        rawSetString:
            rawSetString.present ? rawSetString.value : this.rawSetString,
        createdAt: createdAt ?? this.createdAt,
      );
  ActualStrengthSet copyWithCompanion(ActualStrengthSetsCompanion data) {
    return ActualStrengthSet(
      id: data.id.present ? data.id.value : this.id,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      performedAt:
          data.performedAt.present ? data.performedAt.value : this.performedAt,
      exerciseCanonical: data.exerciseCanonical.present
          ? data.exerciseCanonical.value
          : this.exerciseCanonical,
      prescribedExerciseCanonical: data.prescribedExerciseCanonical.present
          ? data.prescribedExerciseCanonical.value
          : this.prescribedExerciseCanonical,
      substitutionId: data.substitutionId.present
          ? data.substitutionId.value
          : this.substitutionId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rir: data.rir.present ? data.rir.value : this.rir,
      unit: data.unit.present ? data.unit.value : this.unit,
      source: data.source.present ? data.source.value : this.source,
      rawSetString: data.rawSetString.present
          ? data.rawSetString.value
          : this.rawSetString,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActualStrengthSet(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('performedAt: $performedAt, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write('substitutionId: $substitutionId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit, ')
          ..write('source: $source, ')
          ..write('rawSetString: $rawSetString, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      workoutDayId,
      planDayId,
      performedAt,
      exerciseCanonical,
      prescribedExerciseCanonical,
      substitutionId,
      setIndex,
      weight,
      reps,
      rir,
      unit,
      source,
      rawSetString,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActualStrengthSet &&
          other.id == this.id &&
          other.workoutDayId == this.workoutDayId &&
          other.planDayId == this.planDayId &&
          other.performedAt == this.performedAt &&
          other.exerciseCanonical == this.exerciseCanonical &&
          other.prescribedExerciseCanonical ==
              this.prescribedExerciseCanonical &&
          other.substitutionId == this.substitutionId &&
          other.setIndex == this.setIndex &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rir == this.rir &&
          other.unit == this.unit &&
          other.source == this.source &&
          other.rawSetString == this.rawSetString &&
          other.createdAt == this.createdAt);
}

class ActualStrengthSetsCompanion extends UpdateCompanion<ActualStrengthSet> {
  final Value<String> id;
  final Value<String> workoutDayId;
  final Value<String?> planDayId;
  final Value<int?> performedAt;
  final Value<String> exerciseCanonical;
  final Value<String?> prescribedExerciseCanonical;
  final Value<String?> substitutionId;
  final Value<int> setIndex;
  final Value<double?> weight;
  final Value<int?> reps;
  final Value<int?> rir;
  final Value<String> unit;
  final Value<String> source;
  final Value<String?> rawSetString;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ActualStrengthSetsCompanion({
    this.id = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.exerciseCanonical = const Value.absent(),
    this.prescribedExerciseCanonical = const Value.absent(),
    this.substitutionId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.unit = const Value.absent(),
    this.source = const Value.absent(),
    this.rawSetString = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActualStrengthSetsCompanion.insert({
    required String id,
    required String workoutDayId,
    this.planDayId = const Value.absent(),
    this.performedAt = const Value.absent(),
    required String exerciseCanonical,
    this.prescribedExerciseCanonical = const Value.absent(),
    this.substitutionId = const Value.absent(),
    required int setIndex,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    required String unit,
    required String source,
    this.rawSetString = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutDayId = Value(workoutDayId),
        exerciseCanonical = Value(exerciseCanonical),
        setIndex = Value(setIndex),
        unit = Value(unit),
        source = Value(source),
        createdAt = Value(createdAt);
  static Insertable<ActualStrengthSet> custom({
    Expression<String>? id,
    Expression<String>? workoutDayId,
    Expression<String>? planDayId,
    Expression<int>? performedAt,
    Expression<String>? exerciseCanonical,
    Expression<String>? prescribedExerciseCanonical,
    Expression<String>? substitutionId,
    Expression<int>? setIndex,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? rir,
    Expression<String>? unit,
    Expression<String>? source,
    Expression<String>? rawSetString,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (performedAt != null) 'performed_at': performedAt,
      if (exerciseCanonical != null) 'exercise_canonical': exerciseCanonical,
      if (prescribedExerciseCanonical != null)
        'prescribed_exercise_canonical': prescribedExerciseCanonical,
      if (substitutionId != null) 'substitution_id': substitutionId,
      if (setIndex != null) 'set_index': setIndex,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rir != null) 'rir': rir,
      if (unit != null) 'unit': unit,
      if (source != null) 'source': source,
      if (rawSetString != null) 'raw_set_string': rawSetString,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActualStrengthSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutDayId,
      Value<String?>? planDayId,
      Value<int?>? performedAt,
      Value<String>? exerciseCanonical,
      Value<String?>? prescribedExerciseCanonical,
      Value<String?>? substitutionId,
      Value<int>? setIndex,
      Value<double?>? weight,
      Value<int?>? reps,
      Value<int?>? rir,
      Value<String>? unit,
      Value<String>? source,
      Value<String?>? rawSetString,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ActualStrengthSetsCompanion(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      planDayId: planDayId ?? this.planDayId,
      performedAt: performedAt ?? this.performedAt,
      exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
      prescribedExerciseCanonical:
          prescribedExerciseCanonical ?? this.prescribedExerciseCanonical,
      substitutionId: substitutionId ?? this.substitutionId,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      rawSetString: rawSetString ?? this.rawSetString,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<int>(performedAt.value);
    }
    if (exerciseCanonical.present) {
      map['exercise_canonical'] = Variable<String>(exerciseCanonical.value);
    }
    if (prescribedExerciseCanonical.present) {
      map['prescribed_exercise_canonical'] =
          Variable<String>(prescribedExerciseCanonical.value);
    }
    if (substitutionId.present) {
      map['substitution_id'] = Variable<String>(substitutionId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rawSetString.present) {
      map['raw_set_string'] = Variable<String>(rawSetString.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActualStrengthSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('performedAt: $performedAt, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write('substitutionId: $substitutionId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit, ')
          ..write('source: $source, ')
          ..write('rawSetString: $rawSetString, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescribedStrengthSetsTable extends PrescribedStrengthSets
    with TableInfo<$PrescribedStrengthSetsTable, PrescribedStrengthSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescribedStrengthSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutDayIdMeta =
      const VerificationMeta('workoutDayId');
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
      'workout_day_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseCanonicalMeta =
      const VerificationMeta('exerciseCanonical');
  @override
  late final GeneratedColumn<String> exerciseCanonical =
      GeneratedColumn<String>('exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIndexMeta =
      const VerificationMeta('setIndex');
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
      'set_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
      'rir', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, workoutDayId, exerciseCanonical, setIndex, weight, reps, rir, unit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescribed_strength_sets';
  @override
  VerificationContext validateIntegrity(
      Insertable<PrescribedStrengthSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
          _workoutDayIdMeta,
          workoutDayId.isAcceptableOrUnknown(
              data['workout_day_id']!, _workoutDayIdMeta));
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('exercise_canonical')) {
      context.handle(
          _exerciseCanonicalMeta,
          exerciseCanonical.isAcceptableOrUnknown(
              data['exercise_canonical']!, _exerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_exerciseCanonicalMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(_setIndexMeta,
          setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta));
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrescribedStrengthSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescribedStrengthSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_day_id'])!,
      exerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exercise_canonical'])!,
      setIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_index'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rir']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
    );
  }

  @override
  $PrescribedStrengthSetsTable createAlias(String alias) {
    return $PrescribedStrengthSetsTable(attachedDatabase, alias);
  }
}

class PrescribedStrengthSet extends DataClass
    implements Insertable<PrescribedStrengthSet> {
  final String id;
  final String workoutDayId;
  final String exerciseCanonical;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
  const PrescribedStrengthSet(
      {required this.id,
      required this.workoutDayId,
      required this.exerciseCanonical,
      required this.setIndex,
      this.weight,
      this.reps,
      this.rir,
      required this.unit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    map['exercise_canonical'] = Variable<String>(exerciseCanonical);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['unit'] = Variable<String>(unit);
    return map;
  }

  PrescribedStrengthSetsCompanion toCompanion(bool nullToAbsent) {
    return PrescribedStrengthSetsCompanion(
      id: Value(id),
      workoutDayId: Value(workoutDayId),
      exerciseCanonical: Value(exerciseCanonical),
      setIndex: Value(setIndex),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      unit: Value(unit),
    );
  }

  factory PrescribedStrengthSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescribedStrengthSet(
      id: serializer.fromJson<String>(json['id']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      exerciseCanonical: serializer.fromJson<String>(json['exerciseCanonical']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weight: serializer.fromJson<double?>(json['weight']),
      reps: serializer.fromJson<int?>(json['reps']),
      rir: serializer.fromJson<int?>(json['rir']),
      unit: serializer.fromJson<String>(json['unit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'exerciseCanonical': serializer.toJson<String>(exerciseCanonical),
      'setIndex': serializer.toJson<int>(setIndex),
      'weight': serializer.toJson<double?>(weight),
      'reps': serializer.toJson<int?>(reps),
      'rir': serializer.toJson<int?>(rir),
      'unit': serializer.toJson<String>(unit),
    };
  }

  PrescribedStrengthSet copyWith(
          {String? id,
          String? workoutDayId,
          String? exerciseCanonical,
          int? setIndex,
          Value<double?> weight = const Value.absent(),
          Value<int?> reps = const Value.absent(),
          Value<int?> rir = const Value.absent(),
          String? unit}) =>
      PrescribedStrengthSet(
        id: id ?? this.id,
        workoutDayId: workoutDayId ?? this.workoutDayId,
        exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
        setIndex: setIndex ?? this.setIndex,
        weight: weight.present ? weight.value : this.weight,
        reps: reps.present ? reps.value : this.reps,
        rir: rir.present ? rir.value : this.rir,
        unit: unit ?? this.unit,
      );
  PrescribedStrengthSet copyWithCompanion(
      PrescribedStrengthSetsCompanion data) {
    return PrescribedStrengthSet(
      id: data.id.present ? data.id.value : this.id,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      exerciseCanonical: data.exerciseCanonical.present
          ? data.exerciseCanonical.value
          : this.exerciseCanonical,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rir: data.rir.present ? data.rir.value : this.rir,
      unit: data.unit.present ? data.unit.value : this.unit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescribedStrengthSet(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, workoutDayId, exerciseCanonical, setIndex, weight, reps, rir, unit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescribedStrengthSet &&
          other.id == this.id &&
          other.workoutDayId == this.workoutDayId &&
          other.exerciseCanonical == this.exerciseCanonical &&
          other.setIndex == this.setIndex &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rir == this.rir &&
          other.unit == this.unit);
}

class PrescribedStrengthSetsCompanion
    extends UpdateCompanion<PrescribedStrengthSet> {
  final Value<String> id;
  final Value<String> workoutDayId;
  final Value<String> exerciseCanonical;
  final Value<int> setIndex;
  final Value<double?> weight;
  final Value<int?> reps;
  final Value<int?> rir;
  final Value<String> unit;
  final Value<int> rowid;
  const PrescribedStrengthSetsCompanion({
    this.id = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.exerciseCanonical = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.unit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescribedStrengthSetsCompanion.insert({
    required String id,
    required String workoutDayId,
    required String exerciseCanonical,
    required int setIndex,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    required String unit,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutDayId = Value(workoutDayId),
        exerciseCanonical = Value(exerciseCanonical),
        setIndex = Value(setIndex),
        unit = Value(unit);
  static Insertable<PrescribedStrengthSet> custom({
    Expression<String>? id,
    Expression<String>? workoutDayId,
    Expression<String>? exerciseCanonical,
    Expression<int>? setIndex,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? rir,
    Expression<String>? unit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (exerciseCanonical != null) 'exercise_canonical': exerciseCanonical,
      if (setIndex != null) 'set_index': setIndex,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rir != null) 'rir': rir,
      if (unit != null) 'unit': unit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescribedStrengthSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutDayId,
      Value<String>? exerciseCanonical,
      Value<int>? setIndex,
      Value<double?>? weight,
      Value<int?>? reps,
      Value<int?>? rir,
      Value<String>? unit,
      Value<int>? rowid}) {
    return PrescribedStrengthSetsCompanion(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      unit: unit ?? this.unit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (exerciseCanonical.present) {
      map['exercise_canonical'] = Variable<String>(exerciseCanonical.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescribedStrengthSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppPromptTemplatesTable extends AppPromptTemplates
    with TableInfo<$AppPromptTemplatesTable, AppPromptTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPromptTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateKeyMeta =
      const VerificationMeta('templateKey');
  @override
  late final GeneratedColumn<String> templateKey = GeneratedColumn<String>(
      'template_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateTextMeta =
      const VerificationMeta('templateText');
  @override
  late final GeneratedColumn<String> templateText = GeneratedColumn<String>(
      'template_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('user_override'));
  static const VerificationMeta _versionTagMeta =
      const VerificationMeta('versionTag');
  @override
  late final GeneratedColumn<String> versionTag = GeneratedColumn<String>(
      'version_tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [templateKey, templateText, source, versionTag, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_prompt_templates';
  @override
  VerificationContext validateIntegrity(Insertable<AppPromptTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_key')) {
      context.handle(
          _templateKeyMeta,
          templateKey.isAcceptableOrUnknown(
              data['template_key']!, _templateKeyMeta));
    } else if (isInserting) {
      context.missing(_templateKeyMeta);
    }
    if (data.containsKey('template_text')) {
      context.handle(
          _templateTextMeta,
          templateText.isAcceptableOrUnknown(
              data['template_text']!, _templateTextMeta));
    } else if (isInserting) {
      context.missing(_templateTextMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('version_tag')) {
      context.handle(
          _versionTagMeta,
          versionTag.isAcceptableOrUnknown(
              data['version_tag']!, _versionTagMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateKey};
  @override
  AppPromptTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPromptTemplate(
      templateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_key'])!,
      templateText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_text'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      versionTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_tag']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppPromptTemplatesTable createAlias(String alias) {
    return $AppPromptTemplatesTable(attachedDatabase, alias);
  }
}

class AppPromptTemplate extends DataClass
    implements Insertable<AppPromptTemplate> {
  final String templateKey;
  final String templateText;
  final String source;
  final String? versionTag;
  final int updatedAt;
  const AppPromptTemplate(
      {required this.templateKey,
      required this.templateText,
      required this.source,
      this.versionTag,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_key'] = Variable<String>(templateKey);
    map['template_text'] = Variable<String>(templateText);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || versionTag != null) {
      map['version_tag'] = Variable<String>(versionTag);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppPromptTemplatesCompanion toCompanion(bool nullToAbsent) {
    return AppPromptTemplatesCompanion(
      templateKey: Value(templateKey),
      templateText: Value(templateText),
      source: Value(source),
      versionTag: versionTag == null && nullToAbsent
          ? const Value.absent()
          : Value(versionTag),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPromptTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPromptTemplate(
      templateKey: serializer.fromJson<String>(json['templateKey']),
      templateText: serializer.fromJson<String>(json['templateText']),
      source: serializer.fromJson<String>(json['source']),
      versionTag: serializer.fromJson<String?>(json['versionTag']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'templateKey': serializer.toJson<String>(templateKey),
      'templateText': serializer.toJson<String>(templateText),
      'source': serializer.toJson<String>(source),
      'versionTag': serializer.toJson<String?>(versionTag),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppPromptTemplate copyWith(
          {String? templateKey,
          String? templateText,
          String? source,
          Value<String?> versionTag = const Value.absent(),
          int? updatedAt}) =>
      AppPromptTemplate(
        templateKey: templateKey ?? this.templateKey,
        templateText: templateText ?? this.templateText,
        source: source ?? this.source,
        versionTag: versionTag.present ? versionTag.value : this.versionTag,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppPromptTemplate copyWithCompanion(AppPromptTemplatesCompanion data) {
    return AppPromptTemplate(
      templateKey:
          data.templateKey.present ? data.templateKey.value : this.templateKey,
      templateText: data.templateText.present
          ? data.templateText.value
          : this.templateText,
      source: data.source.present ? data.source.value : this.source,
      versionTag:
          data.versionTag.present ? data.versionTag.value : this.versionTag,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPromptTemplate(')
          ..write('templateKey: $templateKey, ')
          ..write('templateText: $templateText, ')
          ..write('source: $source, ')
          ..write('versionTag: $versionTag, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(templateKey, templateText, source, versionTag, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPromptTemplate &&
          other.templateKey == this.templateKey &&
          other.templateText == this.templateText &&
          other.source == this.source &&
          other.versionTag == this.versionTag &&
          other.updatedAt == this.updatedAt);
}

class AppPromptTemplatesCompanion extends UpdateCompanion<AppPromptTemplate> {
  final Value<String> templateKey;
  final Value<String> templateText;
  final Value<String> source;
  final Value<String?> versionTag;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppPromptTemplatesCompanion({
    this.templateKey = const Value.absent(),
    this.templateText = const Value.absent(),
    this.source = const Value.absent(),
    this.versionTag = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPromptTemplatesCompanion.insert({
    required String templateKey,
    required String templateText,
    this.source = const Value.absent(),
    this.versionTag = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : templateKey = Value(templateKey),
        templateText = Value(templateText),
        updatedAt = Value(updatedAt);
  static Insertable<AppPromptTemplate> custom({
    Expression<String>? templateKey,
    Expression<String>? templateText,
    Expression<String>? source,
    Expression<String>? versionTag,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateKey != null) 'template_key': templateKey,
      if (templateText != null) 'template_text': templateText,
      if (source != null) 'source': source,
      if (versionTag != null) 'version_tag': versionTag,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPromptTemplatesCompanion copyWith(
      {Value<String>? templateKey,
      Value<String>? templateText,
      Value<String>? source,
      Value<String?>? versionTag,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return AppPromptTemplatesCompanion(
      templateKey: templateKey ?? this.templateKey,
      templateText: templateText ?? this.templateText,
      source: source ?? this.source,
      versionTag: versionTag ?? this.versionTag,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateKey.present) {
      map['template_key'] = Variable<String>(templateKey.value);
    }
    if (templateText.present) {
      map['template_text'] = Variable<String>(templateText.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (versionTag.present) {
      map['version_tag'] = Variable<String>(versionTag.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPromptTemplatesCompanion(')
          ..write('templateKey: $templateKey, ')
          ..write('templateText: $templateText, ')
          ..write('source: $source, ')
          ..write('versionTag: $versionTag, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SleepNightsTable extends SleepNights
    with TableInfo<$SleepNightsTable, SleepNight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepNightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sleepDateMeta =
      const VerificationMeta('sleepDate');
  @override
  late final GeneratedColumn<String> sleepDate = GeneratedColumn<String>(
      'sleep_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalSleepMinMeta =
      const VerificationMeta('totalSleepMin');
  @override
  late final GeneratedColumn<int> totalSleepMin = GeneratedColumn<int>(
      'total_sleep_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _remMinMeta = const VerificationMeta('remMin');
  @override
  late final GeneratedColumn<int> remMin = GeneratedColumn<int>(
      'rem_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deepMinMeta =
      const VerificationMeta('deepMin');
  @override
  late final GeneratedColumn<int> deepMin = GeneratedColumn<int>(
      'deep_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lightMinMeta =
      const VerificationMeta('lightMin');
  @override
  late final GeneratedColumn<int> lightMin = GeneratedColumn<int>(
      'light_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _awakeMinMeta =
      const VerificationMeta('awakeMin');
  @override
  late final GeneratedColumn<int> awakeMin = GeneratedColumn<int>(
      'awake_min', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sleepDate,
        startTime,
        endTime,
        totalSleepMin,
        remMin,
        deepMin,
        lightMin,
        awakeMin,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_nights';
  @override
  VerificationContext validateIntegrity(Insertable<SleepNight> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sleep_date')) {
      context.handle(_sleepDateMeta,
          sleepDate.isAcceptableOrUnknown(data['sleep_date']!, _sleepDateMeta));
    } else if (isInserting) {
      context.missing(_sleepDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('total_sleep_min')) {
      context.handle(
          _totalSleepMinMeta,
          totalSleepMin.isAcceptableOrUnknown(
              data['total_sleep_min']!, _totalSleepMinMeta));
    }
    if (data.containsKey('rem_min')) {
      context.handle(_remMinMeta,
          remMin.isAcceptableOrUnknown(data['rem_min']!, _remMinMeta));
    }
    if (data.containsKey('deep_min')) {
      context.handle(_deepMinMeta,
          deepMin.isAcceptableOrUnknown(data['deep_min']!, _deepMinMeta));
    }
    if (data.containsKey('light_min')) {
      context.handle(_lightMinMeta,
          lightMin.isAcceptableOrUnknown(data['light_min']!, _lightMinMeta));
    }
    if (data.containsKey('awake_min')) {
      context.handle(_awakeMinMeta,
          awakeMin.isAcceptableOrUnknown(data['awake_min']!, _awakeMinMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepNight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepNight(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sleepDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sleep_date'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time']),
      totalSleepMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_sleep_min']),
      remMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rem_min']),
      deepMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deep_min']),
      lightMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}light_min']),
      awakeMin: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}awake_min']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $SleepNightsTable createAlias(String alias) {
    return $SleepNightsTable(attachedDatabase, alias);
  }
}

class SleepNight extends DataClass implements Insertable<SleepNight> {
  final String id;
  final String sleepDate;
  final int? startTime;
  final int? endTime;
  final int? totalSleepMin;
  final int? remMin;
  final int? deepMin;
  final int? lightMin;
  final int? awakeMin;
  final String source;
  const SleepNight(
      {required this.id,
      required this.sleepDate,
      this.startTime,
      this.endTime,
      this.totalSleepMin,
      this.remMin,
      this.deepMin,
      this.lightMin,
      this.awakeMin,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sleep_date'] = Variable<String>(sleepDate);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<int>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<int>(endTime);
    }
    if (!nullToAbsent || totalSleepMin != null) {
      map['total_sleep_min'] = Variable<int>(totalSleepMin);
    }
    if (!nullToAbsent || remMin != null) {
      map['rem_min'] = Variable<int>(remMin);
    }
    if (!nullToAbsent || deepMin != null) {
      map['deep_min'] = Variable<int>(deepMin);
    }
    if (!nullToAbsent || lightMin != null) {
      map['light_min'] = Variable<int>(lightMin);
    }
    if (!nullToAbsent || awakeMin != null) {
      map['awake_min'] = Variable<int>(awakeMin);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  SleepNightsCompanion toCompanion(bool nullToAbsent) {
    return SleepNightsCompanion(
      id: Value(id),
      sleepDate: Value(sleepDate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      totalSleepMin: totalSleepMin == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSleepMin),
      remMin:
          remMin == null && nullToAbsent ? const Value.absent() : Value(remMin),
      deepMin: deepMin == null && nullToAbsent
          ? const Value.absent()
          : Value(deepMin),
      lightMin: lightMin == null && nullToAbsent
          ? const Value.absent()
          : Value(lightMin),
      awakeMin: awakeMin == null && nullToAbsent
          ? const Value.absent()
          : Value(awakeMin),
      source: Value(source),
    );
  }

  factory SleepNight.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepNight(
      id: serializer.fromJson<String>(json['id']),
      sleepDate: serializer.fromJson<String>(json['sleepDate']),
      startTime: serializer.fromJson<int?>(json['startTime']),
      endTime: serializer.fromJson<int?>(json['endTime']),
      totalSleepMin: serializer.fromJson<int?>(json['totalSleepMin']),
      remMin: serializer.fromJson<int?>(json['remMin']),
      deepMin: serializer.fromJson<int?>(json['deepMin']),
      lightMin: serializer.fromJson<int?>(json['lightMin']),
      awakeMin: serializer.fromJson<int?>(json['awakeMin']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sleepDate': serializer.toJson<String>(sleepDate),
      'startTime': serializer.toJson<int?>(startTime),
      'endTime': serializer.toJson<int?>(endTime),
      'totalSleepMin': serializer.toJson<int?>(totalSleepMin),
      'remMin': serializer.toJson<int?>(remMin),
      'deepMin': serializer.toJson<int?>(deepMin),
      'lightMin': serializer.toJson<int?>(lightMin),
      'awakeMin': serializer.toJson<int?>(awakeMin),
      'source': serializer.toJson<String>(source),
    };
  }

  SleepNight copyWith(
          {String? id,
          String? sleepDate,
          Value<int?> startTime = const Value.absent(),
          Value<int?> endTime = const Value.absent(),
          Value<int?> totalSleepMin = const Value.absent(),
          Value<int?> remMin = const Value.absent(),
          Value<int?> deepMin = const Value.absent(),
          Value<int?> lightMin = const Value.absent(),
          Value<int?> awakeMin = const Value.absent(),
          String? source}) =>
      SleepNight(
        id: id ?? this.id,
        sleepDate: sleepDate ?? this.sleepDate,
        startTime: startTime.present ? startTime.value : this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        totalSleepMin:
            totalSleepMin.present ? totalSleepMin.value : this.totalSleepMin,
        remMin: remMin.present ? remMin.value : this.remMin,
        deepMin: deepMin.present ? deepMin.value : this.deepMin,
        lightMin: lightMin.present ? lightMin.value : this.lightMin,
        awakeMin: awakeMin.present ? awakeMin.value : this.awakeMin,
        source: source ?? this.source,
      );
  SleepNight copyWithCompanion(SleepNightsCompanion data) {
    return SleepNight(
      id: data.id.present ? data.id.value : this.id,
      sleepDate: data.sleepDate.present ? data.sleepDate.value : this.sleepDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      totalSleepMin: data.totalSleepMin.present
          ? data.totalSleepMin.value
          : this.totalSleepMin,
      remMin: data.remMin.present ? data.remMin.value : this.remMin,
      deepMin: data.deepMin.present ? data.deepMin.value : this.deepMin,
      lightMin: data.lightMin.present ? data.lightMin.value : this.lightMin,
      awakeMin: data.awakeMin.present ? data.awakeMin.value : this.awakeMin,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepNight(')
          ..write('id: $id, ')
          ..write('sleepDate: $sleepDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('totalSleepMin: $totalSleepMin, ')
          ..write('remMin: $remMin, ')
          ..write('deepMin: $deepMin, ')
          ..write('lightMin: $lightMin, ')
          ..write('awakeMin: $awakeMin, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sleepDate, startTime, endTime,
      totalSleepMin, remMin, deepMin, lightMin, awakeMin, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepNight &&
          other.id == this.id &&
          other.sleepDate == this.sleepDate &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.totalSleepMin == this.totalSleepMin &&
          other.remMin == this.remMin &&
          other.deepMin == this.deepMin &&
          other.lightMin == this.lightMin &&
          other.awakeMin == this.awakeMin &&
          other.source == this.source);
}

class SleepNightsCompanion extends UpdateCompanion<SleepNight> {
  final Value<String> id;
  final Value<String> sleepDate;
  final Value<int?> startTime;
  final Value<int?> endTime;
  final Value<int?> totalSleepMin;
  final Value<int?> remMin;
  final Value<int?> deepMin;
  final Value<int?> lightMin;
  final Value<int?> awakeMin;
  final Value<String> source;
  final Value<int> rowid;
  const SleepNightsCompanion({
    this.id = const Value.absent(),
    this.sleepDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.totalSleepMin = const Value.absent(),
    this.remMin = const Value.absent(),
    this.deepMin = const Value.absent(),
    this.lightMin = const Value.absent(),
    this.awakeMin = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SleepNightsCompanion.insert({
    required String id,
    required String sleepDate,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.totalSleepMin = const Value.absent(),
    this.remMin = const Value.absent(),
    this.deepMin = const Value.absent(),
    this.lightMin = const Value.absent(),
    this.awakeMin = const Value.absent(),
    required String source,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sleepDate = Value(sleepDate),
        source = Value(source);
  static Insertable<SleepNight> custom({
    Expression<String>? id,
    Expression<String>? sleepDate,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<int>? totalSleepMin,
    Expression<int>? remMin,
    Expression<int>? deepMin,
    Expression<int>? lightMin,
    Expression<int>? awakeMin,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sleepDate != null) 'sleep_date': sleepDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (totalSleepMin != null) 'total_sleep_min': totalSleepMin,
      if (remMin != null) 'rem_min': remMin,
      if (deepMin != null) 'deep_min': deepMin,
      if (lightMin != null) 'light_min': lightMin,
      if (awakeMin != null) 'awake_min': awakeMin,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SleepNightsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sleepDate,
      Value<int?>? startTime,
      Value<int?>? endTime,
      Value<int?>? totalSleepMin,
      Value<int?>? remMin,
      Value<int?>? deepMin,
      Value<int?>? lightMin,
      Value<int?>? awakeMin,
      Value<String>? source,
      Value<int>? rowid}) {
    return SleepNightsCompanion(
      id: id ?? this.id,
      sleepDate: sleepDate ?? this.sleepDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalSleepMin: totalSleepMin ?? this.totalSleepMin,
      remMin: remMin ?? this.remMin,
      deepMin: deepMin ?? this.deepMin,
      lightMin: lightMin ?? this.lightMin,
      awakeMin: awakeMin ?? this.awakeMin,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sleepDate.present) {
      map['sleep_date'] = Variable<String>(sleepDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (totalSleepMin.present) {
      map['total_sleep_min'] = Variable<int>(totalSleepMin.value);
    }
    if (remMin.present) {
      map['rem_min'] = Variable<int>(remMin.value);
    }
    if (deepMin.present) {
      map['deep_min'] = Variable<int>(deepMin.value);
    }
    if (lightMin.present) {
      map['light_min'] = Variable<int>(lightMin.value);
    }
    if (awakeMin.present) {
      map['awake_min'] = Variable<int>(awakeMin.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepNightsCompanion(')
          ..write('id: $id, ')
          ..write('sleepDate: $sleepDate, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('totalSleepMin: $totalSleepMin, ')
          ..write('remMin: $remMin, ')
          ..write('deepMin: $deepMin, ')
          ..write('lightMin: $lightMin, ')
          ..write('awakeMin: $awakeMin, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunSessionsTable extends RunSessions
    with TableInfo<$RunSessionsTable, RunSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runKeyMeta = const VerificationMeta('runKey');
  @override
  late final GeneratedColumn<String> runKey = GeneratedColumn<String>(
      'run_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _workoutDayIdMeta =
      const VerificationMeta('workoutDayId');
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
      'workout_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationSMeta =
      const VerificationMeta('durationS');
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
      'duration_s', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _distanceMMeta =
      const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
      'distance_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<double> avgHr = GeneratedColumn<double>(
      'avg_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<double> maxHr = GeneratedColumn<double>(
      'max_hr', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _treadmillMeta =
      const VerificationMeta('treadmill');
  @override
  late final GeneratedColumn<bool> treadmill = GeneratedColumn<bool>(
      'treadmill', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("treadmill" IN (0, 1))'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activityTypeMeta =
      const VerificationMeta('activityType');
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
      'activity_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _movingTimeSMeta =
      const VerificationMeta('movingTimeS');
  @override
  late final GeneratedColumn<int> movingTimeS = GeneratedColumn<int>(
      'moving_time_s', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _elapsedTimeSMeta =
      const VerificationMeta('elapsedTimeS');
  @override
  late final GeneratedColumn<int> elapsedTimeS = GeneratedColumn<int>(
      'elapsed_time_s', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourcePriorityMeta =
      const VerificationMeta('sourcePriority');
  @override
  late final GeneratedColumn<int> sourcePriority = GeneratedColumn<int>(
      'source_priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _importFileNameMeta =
      const VerificationMeta('importFileName');
  @override
  late final GeneratedColumn<String> importFileName = GeneratedColumn<String>(
      'import_file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawMetricsJsonMeta =
      const VerificationMeta('rawMetricsJson');
  @override
  late final GeneratedColumn<String> rawMetricsJson = GeneratedColumn<String>(
      'raw_metrics_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        runKey,
        workoutDayId,
        planDayId,
        startTime,
        endTime,
        durationS,
        distanceM,
        avgHr,
        maxHr,
        treadmill,
        title,
        activityType,
        calories,
        movingTimeS,
        elapsedTimeS,
        sourcePriority,
        importFileName,
        rawMetricsJson,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<RunSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_key')) {
      context.handle(_runKeyMeta,
          runKey.isAcceptableOrUnknown(data['run_key']!, _runKeyMeta));
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
          _workoutDayIdMeta,
          workoutDayId.isAcceptableOrUnknown(
              data['workout_day_id']!, _workoutDayIdMeta));
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_s')) {
      context.handle(_durationSMeta,
          durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta,
          distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(
          _avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('max_hr')) {
      context.handle(
          _maxHrMeta, maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta));
    }
    if (data.containsKey('treadmill')) {
      context.handle(_treadmillMeta,
          treadmill.isAcceptableOrUnknown(data['treadmill']!, _treadmillMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('activity_type')) {
      context.handle(
          _activityTypeMeta,
          activityType.isAcceptableOrUnknown(
              data['activity_type']!, _activityTypeMeta));
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    }
    if (data.containsKey('moving_time_s')) {
      context.handle(
          _movingTimeSMeta,
          movingTimeS.isAcceptableOrUnknown(
              data['moving_time_s']!, _movingTimeSMeta));
    }
    if (data.containsKey('elapsed_time_s')) {
      context.handle(
          _elapsedTimeSMeta,
          elapsedTimeS.isAcceptableOrUnknown(
              data['elapsed_time_s']!, _elapsedTimeSMeta));
    }
    if (data.containsKey('source_priority')) {
      context.handle(
          _sourcePriorityMeta,
          sourcePriority.isAcceptableOrUnknown(
              data['source_priority']!, _sourcePriorityMeta));
    }
    if (data.containsKey('import_file_name')) {
      context.handle(
          _importFileNameMeta,
          importFileName.isAcceptableOrUnknown(
              data['import_file_name']!, _importFileNameMeta));
    }
    if (data.containsKey('raw_metrics_json')) {
      context.handle(
          _rawMetricsJsonMeta,
          rawMetricsJson.isAcceptableOrUnknown(
              data['raw_metrics_json']!, _rawMetricsJsonMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      runKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_key'])!,
      workoutDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_day_id']),
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time']),
      durationS: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_s']),
      distanceM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_m']),
      avgHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_hr']),
      maxHr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_hr']),
      treadmill: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}treadmill']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      activityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_type']),
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories']),
      movingTimeS: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}moving_time_s']),
      elapsedTimeS: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_time_s']),
      sourcePriority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_priority'])!,
      importFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}import_file_name']),
      rawMetricsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}raw_metrics_json']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $RunSessionsTable createAlias(String alias) {
    return $RunSessionsTable(attachedDatabase, alias);
  }
}

class RunSession extends DataClass implements Insertable<RunSession> {
  final String id;
  final String runKey;
  final String? workoutDayId;
  final String? planDayId;
  final int? startTime;
  final int? endTime;
  final int? durationS;
  final double? distanceM;
  final double? avgHr;
  final double? maxHr;
  final bool? treadmill;
  final String? title;
  final String? activityType;
  final int? calories;
  final int? movingTimeS;
  final int? elapsedTimeS;
  final int sourcePriority;
  final String? importFileName;
  final String? rawMetricsJson;
  final String source;
  const RunSession(
      {required this.id,
      required this.runKey,
      this.workoutDayId,
      this.planDayId,
      this.startTime,
      this.endTime,
      this.durationS,
      this.distanceM,
      this.avgHr,
      this.maxHr,
      this.treadmill,
      this.title,
      this.activityType,
      this.calories,
      this.movingTimeS,
      this.elapsedTimeS,
      required this.sourcePriority,
      this.importFileName,
      this.rawMetricsJson,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_key'] = Variable<String>(runKey);
    if (!nullToAbsent || workoutDayId != null) {
      map['workout_day_id'] = Variable<String>(workoutDayId);
    }
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<String>(planDayId);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<int>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<int>(endTime);
    }
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<int>(durationS);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<double>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<double>(maxHr);
    }
    if (!nullToAbsent || treadmill != null) {
      map['treadmill'] = Variable<bool>(treadmill);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || activityType != null) {
      map['activity_type'] = Variable<String>(activityType);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || movingTimeS != null) {
      map['moving_time_s'] = Variable<int>(movingTimeS);
    }
    if (!nullToAbsent || elapsedTimeS != null) {
      map['elapsed_time_s'] = Variable<int>(elapsedTimeS);
    }
    map['source_priority'] = Variable<int>(sourcePriority);
    if (!nullToAbsent || importFileName != null) {
      map['import_file_name'] = Variable<String>(importFileName);
    }
    if (!nullToAbsent || rawMetricsJson != null) {
      map['raw_metrics_json'] = Variable<String>(rawMetricsJson);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  RunSessionsCompanion toCompanion(bool nullToAbsent) {
    return RunSessionsCompanion(
      id: Value(id),
      runKey: Value(runKey),
      workoutDayId: workoutDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutDayId),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationS: durationS == null && nullToAbsent
          ? const Value.absent()
          : Value(durationS),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      avgHr:
          avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      maxHr:
          maxHr == null && nullToAbsent ? const Value.absent() : Value(maxHr),
      treadmill: treadmill == null && nullToAbsent
          ? const Value.absent()
          : Value(treadmill),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      activityType: activityType == null && nullToAbsent
          ? const Value.absent()
          : Value(activityType),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      movingTimeS: movingTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(movingTimeS),
      elapsedTimeS: elapsedTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(elapsedTimeS),
      sourcePriority: Value(sourcePriority),
      importFileName: importFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(importFileName),
      rawMetricsJson: rawMetricsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rawMetricsJson),
      source: Value(source),
    );
  }

  factory RunSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunSession(
      id: serializer.fromJson<String>(json['id']),
      runKey: serializer.fromJson<String>(json['runKey']),
      workoutDayId: serializer.fromJson<String?>(json['workoutDayId']),
      planDayId: serializer.fromJson<String?>(json['planDayId']),
      startTime: serializer.fromJson<int?>(json['startTime']),
      endTime: serializer.fromJson<int?>(json['endTime']),
      durationS: serializer.fromJson<int?>(json['durationS']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      avgHr: serializer.fromJson<double?>(json['avgHr']),
      maxHr: serializer.fromJson<double?>(json['maxHr']),
      treadmill: serializer.fromJson<bool?>(json['treadmill']),
      title: serializer.fromJson<String?>(json['title']),
      activityType: serializer.fromJson<String?>(json['activityType']),
      calories: serializer.fromJson<int?>(json['calories']),
      movingTimeS: serializer.fromJson<int?>(json['movingTimeS']),
      elapsedTimeS: serializer.fromJson<int?>(json['elapsedTimeS']),
      sourcePriority: serializer.fromJson<int>(json['sourcePriority']),
      importFileName: serializer.fromJson<String?>(json['importFileName']),
      rawMetricsJson: serializer.fromJson<String?>(json['rawMetricsJson']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runKey': serializer.toJson<String>(runKey),
      'workoutDayId': serializer.toJson<String?>(workoutDayId),
      'planDayId': serializer.toJson<String?>(planDayId),
      'startTime': serializer.toJson<int?>(startTime),
      'endTime': serializer.toJson<int?>(endTime),
      'durationS': serializer.toJson<int?>(durationS),
      'distanceM': serializer.toJson<double?>(distanceM),
      'avgHr': serializer.toJson<double?>(avgHr),
      'maxHr': serializer.toJson<double?>(maxHr),
      'treadmill': serializer.toJson<bool?>(treadmill),
      'title': serializer.toJson<String?>(title),
      'activityType': serializer.toJson<String?>(activityType),
      'calories': serializer.toJson<int?>(calories),
      'movingTimeS': serializer.toJson<int?>(movingTimeS),
      'elapsedTimeS': serializer.toJson<int?>(elapsedTimeS),
      'sourcePriority': serializer.toJson<int>(sourcePriority),
      'importFileName': serializer.toJson<String?>(importFileName),
      'rawMetricsJson': serializer.toJson<String?>(rawMetricsJson),
      'source': serializer.toJson<String>(source),
    };
  }

  RunSession copyWith(
          {String? id,
          String? runKey,
          Value<String?> workoutDayId = const Value.absent(),
          Value<String?> planDayId = const Value.absent(),
          Value<int?> startTime = const Value.absent(),
          Value<int?> endTime = const Value.absent(),
          Value<int?> durationS = const Value.absent(),
          Value<double?> distanceM = const Value.absent(),
          Value<double?> avgHr = const Value.absent(),
          Value<double?> maxHr = const Value.absent(),
          Value<bool?> treadmill = const Value.absent(),
          Value<String?> title = const Value.absent(),
          Value<String?> activityType = const Value.absent(),
          Value<int?> calories = const Value.absent(),
          Value<int?> movingTimeS = const Value.absent(),
          Value<int?> elapsedTimeS = const Value.absent(),
          int? sourcePriority,
          Value<String?> importFileName = const Value.absent(),
          Value<String?> rawMetricsJson = const Value.absent(),
          String? source}) =>
      RunSession(
        id: id ?? this.id,
        runKey: runKey ?? this.runKey,
        workoutDayId:
            workoutDayId.present ? workoutDayId.value : this.workoutDayId,
        planDayId: planDayId.present ? planDayId.value : this.planDayId,
        startTime: startTime.present ? startTime.value : this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationS: durationS.present ? durationS.value : this.durationS,
        distanceM: distanceM.present ? distanceM.value : this.distanceM,
        avgHr: avgHr.present ? avgHr.value : this.avgHr,
        maxHr: maxHr.present ? maxHr.value : this.maxHr,
        treadmill: treadmill.present ? treadmill.value : this.treadmill,
        title: title.present ? title.value : this.title,
        activityType:
            activityType.present ? activityType.value : this.activityType,
        calories: calories.present ? calories.value : this.calories,
        movingTimeS: movingTimeS.present ? movingTimeS.value : this.movingTimeS,
        elapsedTimeS:
            elapsedTimeS.present ? elapsedTimeS.value : this.elapsedTimeS,
        sourcePriority: sourcePriority ?? this.sourcePriority,
        importFileName:
            importFileName.present ? importFileName.value : this.importFileName,
        rawMetricsJson:
            rawMetricsJson.present ? rawMetricsJson.value : this.rawMetricsJson,
        source: source ?? this.source,
      );
  RunSession copyWithCompanion(RunSessionsCompanion data) {
    return RunSession(
      id: data.id.present ? data.id.value : this.id,
      runKey: data.runKey.present ? data.runKey.value : this.runKey,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      treadmill: data.treadmill.present ? data.treadmill.value : this.treadmill,
      title: data.title.present ? data.title.value : this.title,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      calories: data.calories.present ? data.calories.value : this.calories,
      movingTimeS:
          data.movingTimeS.present ? data.movingTimeS.value : this.movingTimeS,
      elapsedTimeS: data.elapsedTimeS.present
          ? data.elapsedTimeS.value
          : this.elapsedTimeS,
      sourcePriority: data.sourcePriority.present
          ? data.sourcePriority.value
          : this.sourcePriority,
      importFileName: data.importFileName.present
          ? data.importFileName.value
          : this.importFileName,
      rawMetricsJson: data.rawMetricsJson.present
          ? data.rawMetricsJson.value
          : this.rawMetricsJson,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunSession(')
          ..write('id: $id, ')
          ..write('runKey: $runKey, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('treadmill: $treadmill, ')
          ..write('title: $title, ')
          ..write('activityType: $activityType, ')
          ..write('calories: $calories, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('elapsedTimeS: $elapsedTimeS, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('importFileName: $importFileName, ')
          ..write('rawMetricsJson: $rawMetricsJson, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      runKey,
      workoutDayId,
      planDayId,
      startTime,
      endTime,
      durationS,
      distanceM,
      avgHr,
      maxHr,
      treadmill,
      title,
      activityType,
      calories,
      movingTimeS,
      elapsedTimeS,
      sourcePriority,
      importFileName,
      rawMetricsJson,
      source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunSession &&
          other.id == this.id &&
          other.runKey == this.runKey &&
          other.workoutDayId == this.workoutDayId &&
          other.planDayId == this.planDayId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationS == this.durationS &&
          other.distanceM == this.distanceM &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.treadmill == this.treadmill &&
          other.title == this.title &&
          other.activityType == this.activityType &&
          other.calories == this.calories &&
          other.movingTimeS == this.movingTimeS &&
          other.elapsedTimeS == this.elapsedTimeS &&
          other.sourcePriority == this.sourcePriority &&
          other.importFileName == this.importFileName &&
          other.rawMetricsJson == this.rawMetricsJson &&
          other.source == this.source);
}

class RunSessionsCompanion extends UpdateCompanion<RunSession> {
  final Value<String> id;
  final Value<String> runKey;
  final Value<String?> workoutDayId;
  final Value<String?> planDayId;
  final Value<int?> startTime;
  final Value<int?> endTime;
  final Value<int?> durationS;
  final Value<double?> distanceM;
  final Value<double?> avgHr;
  final Value<double?> maxHr;
  final Value<bool?> treadmill;
  final Value<String?> title;
  final Value<String?> activityType;
  final Value<int?> calories;
  final Value<int?> movingTimeS;
  final Value<int?> elapsedTimeS;
  final Value<int> sourcePriority;
  final Value<String?> importFileName;
  final Value<String?> rawMetricsJson;
  final Value<String> source;
  final Value<int> rowid;
  const RunSessionsCompanion({
    this.id = const Value.absent(),
    this.runKey = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.treadmill = const Value.absent(),
    this.title = const Value.absent(),
    this.activityType = const Value.absent(),
    this.calories = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.elapsedTimeS = const Value.absent(),
    this.sourcePriority = const Value.absent(),
    this.importFileName = const Value.absent(),
    this.rawMetricsJson = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunSessionsCompanion.insert({
    required String id,
    this.runKey = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.treadmill = const Value.absent(),
    this.title = const Value.absent(),
    this.activityType = const Value.absent(),
    this.calories = const Value.absent(),
    this.movingTimeS = const Value.absent(),
    this.elapsedTimeS = const Value.absent(),
    this.sourcePriority = const Value.absent(),
    this.importFileName = const Value.absent(),
    this.rawMetricsJson = const Value.absent(),
    required String source,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        source = Value(source);
  static Insertable<RunSession> custom({
    Expression<String>? id,
    Expression<String>? runKey,
    Expression<String>? workoutDayId,
    Expression<String>? planDayId,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<int>? durationS,
    Expression<double>? distanceM,
    Expression<double>? avgHr,
    Expression<double>? maxHr,
    Expression<bool>? treadmill,
    Expression<String>? title,
    Expression<String>? activityType,
    Expression<int>? calories,
    Expression<int>? movingTimeS,
    Expression<int>? elapsedTimeS,
    Expression<int>? sourcePriority,
    Expression<String>? importFileName,
    Expression<String>? rawMetricsJson,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runKey != null) 'run_key': runKey,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationS != null) 'duration_s': durationS,
      if (distanceM != null) 'distance_m': distanceM,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (treadmill != null) 'treadmill': treadmill,
      if (title != null) 'title': title,
      if (activityType != null) 'activity_type': activityType,
      if (calories != null) 'calories': calories,
      if (movingTimeS != null) 'moving_time_s': movingTimeS,
      if (elapsedTimeS != null) 'elapsed_time_s': elapsedTimeS,
      if (sourcePriority != null) 'source_priority': sourcePriority,
      if (importFileName != null) 'import_file_name': importFileName,
      if (rawMetricsJson != null) 'raw_metrics_json': rawMetricsJson,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? runKey,
      Value<String?>? workoutDayId,
      Value<String?>? planDayId,
      Value<int?>? startTime,
      Value<int?>? endTime,
      Value<int?>? durationS,
      Value<double?>? distanceM,
      Value<double?>? avgHr,
      Value<double?>? maxHr,
      Value<bool?>? treadmill,
      Value<String?>? title,
      Value<String?>? activityType,
      Value<int?>? calories,
      Value<int?>? movingTimeS,
      Value<int?>? elapsedTimeS,
      Value<int>? sourcePriority,
      Value<String?>? importFileName,
      Value<String?>? rawMetricsJson,
      Value<String>? source,
      Value<int>? rowid}) {
    return RunSessionsCompanion(
      id: id ?? this.id,
      runKey: runKey ?? this.runKey,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      planDayId: planDayId ?? this.planDayId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationS: durationS ?? this.durationS,
      distanceM: distanceM ?? this.distanceM,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      treadmill: treadmill ?? this.treadmill,
      title: title ?? this.title,
      activityType: activityType ?? this.activityType,
      calories: calories ?? this.calories,
      movingTimeS: movingTimeS ?? this.movingTimeS,
      elapsedTimeS: elapsedTimeS ?? this.elapsedTimeS,
      sourcePriority: sourcePriority ?? this.sourcePriority,
      importFileName: importFileName ?? this.importFileName,
      rawMetricsJson: rawMetricsJson ?? this.rawMetricsJson,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runKey.present) {
      map['run_key'] = Variable<String>(runKey.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<double>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<double>(maxHr.value);
    }
    if (treadmill.present) {
      map['treadmill'] = Variable<bool>(treadmill.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (movingTimeS.present) {
      map['moving_time_s'] = Variable<int>(movingTimeS.value);
    }
    if (elapsedTimeS.present) {
      map['elapsed_time_s'] = Variable<int>(elapsedTimeS.value);
    }
    if (sourcePriority.present) {
      map['source_priority'] = Variable<int>(sourcePriority.value);
    }
    if (importFileName.present) {
      map['import_file_name'] = Variable<String>(importFileName.value);
    }
    if (rawMetricsJson.present) {
      map['raw_metrics_json'] = Variable<String>(rawMetricsJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunSessionsCompanion(')
          ..write('id: $id, ')
          ..write('runKey: $runKey, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('treadmill: $treadmill, ')
          ..write('title: $title, ')
          ..write('activityType: $activityType, ')
          ..write('calories: $calories, ')
          ..write('movingTimeS: $movingTimeS, ')
          ..write('elapsedTimeS: $elapsedTimeS, ')
          ..write('sourcePriority: $sourcePriority, ')
          ..write('importFileName: $importFileName, ')
          ..write('rawMetricsJson: $rawMetricsJson, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunSegmentsTable extends RunSegments
    with TableInfo<$RunSegmentsTable, RunSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runSessionIdMeta =
      const VerificationMeta('runSessionId');
  @override
  late final GeneratedColumn<String> runSessionId = GeneratedColumn<String>(
      'run_session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
      'idx', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSMeta =
      const VerificationMeta('durationS');
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
      'duration_s', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _distanceMMeta =
      const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
      'distance_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _speedMpsMeta =
      const VerificationMeta('speedMps');
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
      'speed_mps', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, runSessionId, idx, durationS, distanceM, speedMps];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_segments';
  @override
  VerificationContext validateIntegrity(Insertable<RunSegment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_session_id')) {
      context.handle(
          _runSessionIdMeta,
          runSessionId.isAcceptableOrUnknown(
              data['run_session_id']!, _runSessionIdMeta));
    } else if (isInserting) {
      context.missing(_runSessionIdMeta);
    }
    if (data.containsKey('idx')) {
      context.handle(
          _idxMeta, idx.isAcceptableOrUnknown(data['idx']!, _idxMeta));
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('duration_s')) {
      context.handle(_durationSMeta,
          durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta,
          distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    if (data.containsKey('speed_mps')) {
      context.handle(_speedMpsMeta,
          speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunSegment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      runSessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_session_id'])!,
      idx: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}idx'])!,
      durationS: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_s']),
      distanceM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_m']),
      speedMps: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed_mps']),
    );
  }

  @override
  $RunSegmentsTable createAlias(String alias) {
    return $RunSegmentsTable(attachedDatabase, alias);
  }
}

class RunSegment extends DataClass implements Insertable<RunSegment> {
  final String id;
  final String runSessionId;
  final int idx;
  final int? durationS;
  final double? distanceM;
  final double? speedMps;
  const RunSegment(
      {required this.id,
      required this.runSessionId,
      required this.idx,
      this.durationS,
      this.distanceM,
      this.speedMps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_session_id'] = Variable<String>(runSessionId);
    map['idx'] = Variable<int>(idx);
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<int>(durationS);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    return map;
  }

  RunSegmentsCompanion toCompanion(bool nullToAbsent) {
    return RunSegmentsCompanion(
      id: Value(id),
      runSessionId: Value(runSessionId),
      idx: Value(idx),
      durationS: durationS == null && nullToAbsent
          ? const Value.absent()
          : Value(durationS),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
    );
  }

  factory RunSegment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunSegment(
      id: serializer.fromJson<String>(json['id']),
      runSessionId: serializer.fromJson<String>(json['runSessionId']),
      idx: serializer.fromJson<int>(json['idx']),
      durationS: serializer.fromJson<int?>(json['durationS']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runSessionId': serializer.toJson<String>(runSessionId),
      'idx': serializer.toJson<int>(idx),
      'durationS': serializer.toJson<int?>(durationS),
      'distanceM': serializer.toJson<double?>(distanceM),
      'speedMps': serializer.toJson<double?>(speedMps),
    };
  }

  RunSegment copyWith(
          {String? id,
          String? runSessionId,
          int? idx,
          Value<int?> durationS = const Value.absent(),
          Value<double?> distanceM = const Value.absent(),
          Value<double?> speedMps = const Value.absent()}) =>
      RunSegment(
        id: id ?? this.id,
        runSessionId: runSessionId ?? this.runSessionId,
        idx: idx ?? this.idx,
        durationS: durationS.present ? durationS.value : this.durationS,
        distanceM: distanceM.present ? distanceM.value : this.distanceM,
        speedMps: speedMps.present ? speedMps.value : this.speedMps,
      );
  RunSegment copyWithCompanion(RunSegmentsCompanion data) {
    return RunSegment(
      id: data.id.present ? data.id.value : this.id,
      runSessionId: data.runSessionId.present
          ? data.runSessionId.value
          : this.runSessionId,
      idx: data.idx.present ? data.idx.value : this.idx,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunSegment(')
          ..write('id: $id, ')
          ..write('runSessionId: $runSessionId, ')
          ..write('idx: $idx, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('speedMps: $speedMps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, runSessionId, idx, durationS, distanceM, speedMps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunSegment &&
          other.id == this.id &&
          other.runSessionId == this.runSessionId &&
          other.idx == this.idx &&
          other.durationS == this.durationS &&
          other.distanceM == this.distanceM &&
          other.speedMps == this.speedMps);
}

class RunSegmentsCompanion extends UpdateCompanion<RunSegment> {
  final Value<String> id;
  final Value<String> runSessionId;
  final Value<int> idx;
  final Value<int?> durationS;
  final Value<double?> distanceM;
  final Value<double?> speedMps;
  final Value<int> rowid;
  const RunSegmentsCompanion({
    this.id = const Value.absent(),
    this.runSessionId = const Value.absent(),
    this.idx = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunSegmentsCompanion.insert({
    required String id,
    required String runSessionId,
    required int idx,
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        runSessionId = Value(runSessionId),
        idx = Value(idx);
  static Insertable<RunSegment> custom({
    Expression<String>? id,
    Expression<String>? runSessionId,
    Expression<int>? idx,
    Expression<int>? durationS,
    Expression<double>? distanceM,
    Expression<double>? speedMps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runSessionId != null) 'run_session_id': runSessionId,
      if (idx != null) 'idx': idx,
      if (durationS != null) 'duration_s': durationS,
      if (distanceM != null) 'distance_m': distanceM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunSegmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? runSessionId,
      Value<int>? idx,
      Value<int?>? durationS,
      Value<double?>? distanceM,
      Value<double?>? speedMps,
      Value<int>? rowid}) {
    return RunSegmentsCompanion(
      id: id ?? this.id,
      runSessionId: runSessionId ?? this.runSessionId,
      idx: idx ?? this.idx,
      durationS: durationS ?? this.durationS,
      distanceM: distanceM ?? this.distanceM,
      speedMps: speedMps ?? this.speedMps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runSessionId.present) {
      map['run_session_id'] = Variable<String>(runSessionId.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('runSessionId: $runSessionId, ')
          ..write('idx: $idx, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('speedMps: $speedMps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunSessionDetailsTable extends RunSessionDetails
    with TableInfo<$RunSessionDetailsTable, RunSessionDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunSessionDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runSessionIdMeta =
      const VerificationMeta('runSessionId');
  @override
  late final GeneratedColumn<String> runSessionId = GeneratedColumn<String>(
      'run_session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _favoriteMeta =
      const VerificationMeta('favorite');
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
      'favorite', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("favorite" IN (0, 1))'));
  static const VerificationMeta _aerobicTeMeta =
      const VerificationMeta('aerobicTe');
  @override
  late final GeneratedColumn<double> aerobicTe = GeneratedColumn<double>(
      'aerobic_te', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgRunCadenceMeta =
      const VerificationMeta('avgRunCadence');
  @override
  late final GeneratedColumn<double> avgRunCadence = GeneratedColumn<double>(
      'avg_run_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxRunCadenceMeta =
      const VerificationMeta('maxRunCadence');
  @override
  late final GeneratedColumn<double> maxRunCadence = GeneratedColumn<double>(
      'max_run_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgPaceSMeta =
      const VerificationMeta('avgPaceS');
  @override
  late final GeneratedColumn<double> avgPaceS = GeneratedColumn<double>(
      'avg_pace_s', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bestPaceSMeta =
      const VerificationMeta('bestPaceS');
  @override
  late final GeneratedColumn<double> bestPaceS = GeneratedColumn<double>(
      'best_pace_s', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalAscentMeta =
      const VerificationMeta('totalAscent');
  @override
  late final GeneratedColumn<double> totalAscent = GeneratedColumn<double>(
      'total_ascent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalDescentMeta =
      const VerificationMeta('totalDescent');
  @override
  late final GeneratedColumn<double> totalDescent = GeneratedColumn<double>(
      'total_descent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgStrideLengthMMeta =
      const VerificationMeta('avgStrideLengthM');
  @override
  late final GeneratedColumn<double> avgStrideLengthM = GeneratedColumn<double>(
      'avg_stride_length_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _trainingStressScoreMeta =
      const VerificationMeta('trainingStressScore');
  @override
  late final GeneratedColumn<double> trainingStressScore =
      GeneratedColumn<double>('training_stress_score', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
      'steps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minTempMeta =
      const VerificationMeta('minTemp');
  @override
  late final GeneratedColumn<double> minTemp = GeneratedColumn<double>(
      'min_temp', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxTempMeta =
      const VerificationMeta('maxTemp');
  @override
  late final GeneratedColumn<double> maxTemp = GeneratedColumn<double>(
      'max_temp', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _decompressionMeta =
      const VerificationMeta('decompression');
  @override
  late final GeneratedColumn<String> decompression = GeneratedColumn<String>(
      'decompression', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bestLapTimeSMeta =
      const VerificationMeta('bestLapTimeS');
  @override
  late final GeneratedColumn<double> bestLapTimeS = GeneratedColumn<double>(
      'best_lap_time_s', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _numberOfLapsMeta =
      const VerificationMeta('numberOfLaps');
  @override
  late final GeneratedColumn<int> numberOfLaps = GeneratedColumn<int>(
      'number_of_laps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minElevationMeta =
      const VerificationMeta('minElevation');
  @override
  late final GeneratedColumn<double> minElevation = GeneratedColumn<double>(
      'min_elevation', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxElevationMeta =
      const VerificationMeta('maxElevation');
  @override
  late final GeneratedColumn<double> maxElevation = GeneratedColumn<double>(
      'max_elevation', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _rawMetricsJsonMeta =
      const VerificationMeta('rawMetricsJson');
  @override
  late final GeneratedColumn<String> rawMetricsJson = GeneratedColumn<String>(
      'raw_metrics_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        runSessionId,
        favorite,
        aerobicTe,
        avgRunCadence,
        maxRunCadence,
        avgPaceS,
        bestPaceS,
        totalAscent,
        totalDescent,
        avgStrideLengthM,
        trainingStressScore,
        steps,
        minTemp,
        maxTemp,
        decompression,
        bestLapTimeS,
        numberOfLaps,
        minElevation,
        maxElevation,
        rawMetricsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_session_details';
  @override
  VerificationContext validateIntegrity(Insertable<RunSessionDetail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_session_id')) {
      context.handle(
          _runSessionIdMeta,
          runSessionId.isAcceptableOrUnknown(
              data['run_session_id']!, _runSessionIdMeta));
    } else if (isInserting) {
      context.missing(_runSessionIdMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(_favoriteMeta,
          favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta));
    }
    if (data.containsKey('aerobic_te')) {
      context.handle(_aerobicTeMeta,
          aerobicTe.isAcceptableOrUnknown(data['aerobic_te']!, _aerobicTeMeta));
    }
    if (data.containsKey('avg_run_cadence')) {
      context.handle(
          _avgRunCadenceMeta,
          avgRunCadence.isAcceptableOrUnknown(
              data['avg_run_cadence']!, _avgRunCadenceMeta));
    }
    if (data.containsKey('max_run_cadence')) {
      context.handle(
          _maxRunCadenceMeta,
          maxRunCadence.isAcceptableOrUnknown(
              data['max_run_cadence']!, _maxRunCadenceMeta));
    }
    if (data.containsKey('avg_pace_s')) {
      context.handle(_avgPaceSMeta,
          avgPaceS.isAcceptableOrUnknown(data['avg_pace_s']!, _avgPaceSMeta));
    }
    if (data.containsKey('best_pace_s')) {
      context.handle(
          _bestPaceSMeta,
          bestPaceS.isAcceptableOrUnknown(
              data['best_pace_s']!, _bestPaceSMeta));
    }
    if (data.containsKey('total_ascent')) {
      context.handle(
          _totalAscentMeta,
          totalAscent.isAcceptableOrUnknown(
              data['total_ascent']!, _totalAscentMeta));
    }
    if (data.containsKey('total_descent')) {
      context.handle(
          _totalDescentMeta,
          totalDescent.isAcceptableOrUnknown(
              data['total_descent']!, _totalDescentMeta));
    }
    if (data.containsKey('avg_stride_length_m')) {
      context.handle(
          _avgStrideLengthMMeta,
          avgStrideLengthM.isAcceptableOrUnknown(
              data['avg_stride_length_m']!, _avgStrideLengthMMeta));
    }
    if (data.containsKey('training_stress_score')) {
      context.handle(
          _trainingStressScoreMeta,
          trainingStressScore.isAcceptableOrUnknown(
              data['training_stress_score']!, _trainingStressScoreMeta));
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('min_temp')) {
      context.handle(_minTempMeta,
          minTemp.isAcceptableOrUnknown(data['min_temp']!, _minTempMeta));
    }
    if (data.containsKey('max_temp')) {
      context.handle(_maxTempMeta,
          maxTemp.isAcceptableOrUnknown(data['max_temp']!, _maxTempMeta));
    }
    if (data.containsKey('decompression')) {
      context.handle(
          _decompressionMeta,
          decompression.isAcceptableOrUnknown(
              data['decompression']!, _decompressionMeta));
    }
    if (data.containsKey('best_lap_time_s')) {
      context.handle(
          _bestLapTimeSMeta,
          bestLapTimeS.isAcceptableOrUnknown(
              data['best_lap_time_s']!, _bestLapTimeSMeta));
    }
    if (data.containsKey('number_of_laps')) {
      context.handle(
          _numberOfLapsMeta,
          numberOfLaps.isAcceptableOrUnknown(
              data['number_of_laps']!, _numberOfLapsMeta));
    }
    if (data.containsKey('min_elevation')) {
      context.handle(
          _minElevationMeta,
          minElevation.isAcceptableOrUnknown(
              data['min_elevation']!, _minElevationMeta));
    }
    if (data.containsKey('max_elevation')) {
      context.handle(
          _maxElevationMeta,
          maxElevation.isAcceptableOrUnknown(
              data['max_elevation']!, _maxElevationMeta));
    }
    if (data.containsKey('raw_metrics_json')) {
      context.handle(
          _rawMetricsJsonMeta,
          rawMetricsJson.isAcceptableOrUnknown(
              data['raw_metrics_json']!, _rawMetricsJsonMeta));
    } else if (isInserting) {
      context.missing(_rawMetricsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runSessionId};
  @override
  RunSessionDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunSessionDetail(
      runSessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_session_id'])!,
      favorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}favorite']),
      aerobicTe: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}aerobic_te']),
      avgRunCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_run_cadence']),
      maxRunCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_run_cadence']),
      avgPaceS: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_pace_s']),
      bestPaceS: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}best_pace_s']),
      totalAscent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_ascent']),
      totalDescent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_descent']),
      avgStrideLengthM: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}avg_stride_length_m']),
      trainingStressScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}training_stress_score']),
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps']),
      minTemp: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_temp']),
      maxTemp: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_temp']),
      decompression: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}decompression']),
      bestLapTimeS: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}best_lap_time_s']),
      numberOfLaps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number_of_laps']),
      minElevation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_elevation']),
      maxElevation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_elevation']),
      rawMetricsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}raw_metrics_json'])!,
    );
  }

  @override
  $RunSessionDetailsTable createAlias(String alias) {
    return $RunSessionDetailsTable(attachedDatabase, alias);
  }
}

class RunSessionDetail extends DataClass
    implements Insertable<RunSessionDetail> {
  final String runSessionId;
  final bool? favorite;
  final double? aerobicTe;
  final double? avgRunCadence;
  final double? maxRunCadence;
  final double? avgPaceS;
  final double? bestPaceS;
  final double? totalAscent;
  final double? totalDescent;
  final double? avgStrideLengthM;
  final double? trainingStressScore;
  final int? steps;
  final double? minTemp;
  final double? maxTemp;
  final String? decompression;
  final double? bestLapTimeS;
  final int? numberOfLaps;
  final double? minElevation;
  final double? maxElevation;
  final String rawMetricsJson;
  const RunSessionDetail(
      {required this.runSessionId,
      this.favorite,
      this.aerobicTe,
      this.avgRunCadence,
      this.maxRunCadence,
      this.avgPaceS,
      this.bestPaceS,
      this.totalAscent,
      this.totalDescent,
      this.avgStrideLengthM,
      this.trainingStressScore,
      this.steps,
      this.minTemp,
      this.maxTemp,
      this.decompression,
      this.bestLapTimeS,
      this.numberOfLaps,
      this.minElevation,
      this.maxElevation,
      required this.rawMetricsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_session_id'] = Variable<String>(runSessionId);
    if (!nullToAbsent || favorite != null) {
      map['favorite'] = Variable<bool>(favorite);
    }
    if (!nullToAbsent || aerobicTe != null) {
      map['aerobic_te'] = Variable<double>(aerobicTe);
    }
    if (!nullToAbsent || avgRunCadence != null) {
      map['avg_run_cadence'] = Variable<double>(avgRunCadence);
    }
    if (!nullToAbsent || maxRunCadence != null) {
      map['max_run_cadence'] = Variable<double>(maxRunCadence);
    }
    if (!nullToAbsent || avgPaceS != null) {
      map['avg_pace_s'] = Variable<double>(avgPaceS);
    }
    if (!nullToAbsent || bestPaceS != null) {
      map['best_pace_s'] = Variable<double>(bestPaceS);
    }
    if (!nullToAbsent || totalAscent != null) {
      map['total_ascent'] = Variable<double>(totalAscent);
    }
    if (!nullToAbsent || totalDescent != null) {
      map['total_descent'] = Variable<double>(totalDescent);
    }
    if (!nullToAbsent || avgStrideLengthM != null) {
      map['avg_stride_length_m'] = Variable<double>(avgStrideLengthM);
    }
    if (!nullToAbsent || trainingStressScore != null) {
      map['training_stress_score'] = Variable<double>(trainingStressScore);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || minTemp != null) {
      map['min_temp'] = Variable<double>(minTemp);
    }
    if (!nullToAbsent || maxTemp != null) {
      map['max_temp'] = Variable<double>(maxTemp);
    }
    if (!nullToAbsent || decompression != null) {
      map['decompression'] = Variable<String>(decompression);
    }
    if (!nullToAbsent || bestLapTimeS != null) {
      map['best_lap_time_s'] = Variable<double>(bestLapTimeS);
    }
    if (!nullToAbsent || numberOfLaps != null) {
      map['number_of_laps'] = Variable<int>(numberOfLaps);
    }
    if (!nullToAbsent || minElevation != null) {
      map['min_elevation'] = Variable<double>(minElevation);
    }
    if (!nullToAbsent || maxElevation != null) {
      map['max_elevation'] = Variable<double>(maxElevation);
    }
    map['raw_metrics_json'] = Variable<String>(rawMetricsJson);
    return map;
  }

  RunSessionDetailsCompanion toCompanion(bool nullToAbsent) {
    return RunSessionDetailsCompanion(
      runSessionId: Value(runSessionId),
      favorite: favorite == null && nullToAbsent
          ? const Value.absent()
          : Value(favorite),
      aerobicTe: aerobicTe == null && nullToAbsent
          ? const Value.absent()
          : Value(aerobicTe),
      avgRunCadence: avgRunCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgRunCadence),
      maxRunCadence: maxRunCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(maxRunCadence),
      avgPaceS: avgPaceS == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPaceS),
      bestPaceS: bestPaceS == null && nullToAbsent
          ? const Value.absent()
          : Value(bestPaceS),
      totalAscent: totalAscent == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAscent),
      totalDescent: totalDescent == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDescent),
      avgStrideLengthM: avgStrideLengthM == null && nullToAbsent
          ? const Value.absent()
          : Value(avgStrideLengthM),
      trainingStressScore: trainingStressScore == null && nullToAbsent
          ? const Value.absent()
          : Value(trainingStressScore),
      steps:
          steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      minTemp: minTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(minTemp),
      maxTemp: maxTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTemp),
      decompression: decompression == null && nullToAbsent
          ? const Value.absent()
          : Value(decompression),
      bestLapTimeS: bestLapTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(bestLapTimeS),
      numberOfLaps: numberOfLaps == null && nullToAbsent
          ? const Value.absent()
          : Value(numberOfLaps),
      minElevation: minElevation == null && nullToAbsent
          ? const Value.absent()
          : Value(minElevation),
      maxElevation: maxElevation == null && nullToAbsent
          ? const Value.absent()
          : Value(maxElevation),
      rawMetricsJson: Value(rawMetricsJson),
    );
  }

  factory RunSessionDetail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunSessionDetail(
      runSessionId: serializer.fromJson<String>(json['runSessionId']),
      favorite: serializer.fromJson<bool?>(json['favorite']),
      aerobicTe: serializer.fromJson<double?>(json['aerobicTe']),
      avgRunCadence: serializer.fromJson<double?>(json['avgRunCadence']),
      maxRunCadence: serializer.fromJson<double?>(json['maxRunCadence']),
      avgPaceS: serializer.fromJson<double?>(json['avgPaceS']),
      bestPaceS: serializer.fromJson<double?>(json['bestPaceS']),
      totalAscent: serializer.fromJson<double?>(json['totalAscent']),
      totalDescent: serializer.fromJson<double?>(json['totalDescent']),
      avgStrideLengthM: serializer.fromJson<double?>(json['avgStrideLengthM']),
      trainingStressScore:
          serializer.fromJson<double?>(json['trainingStressScore']),
      steps: serializer.fromJson<int?>(json['steps']),
      minTemp: serializer.fromJson<double?>(json['minTemp']),
      maxTemp: serializer.fromJson<double?>(json['maxTemp']),
      decompression: serializer.fromJson<String?>(json['decompression']),
      bestLapTimeS: serializer.fromJson<double?>(json['bestLapTimeS']),
      numberOfLaps: serializer.fromJson<int?>(json['numberOfLaps']),
      minElevation: serializer.fromJson<double?>(json['minElevation']),
      maxElevation: serializer.fromJson<double?>(json['maxElevation']),
      rawMetricsJson: serializer.fromJson<String>(json['rawMetricsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runSessionId': serializer.toJson<String>(runSessionId),
      'favorite': serializer.toJson<bool?>(favorite),
      'aerobicTe': serializer.toJson<double?>(aerobicTe),
      'avgRunCadence': serializer.toJson<double?>(avgRunCadence),
      'maxRunCadence': serializer.toJson<double?>(maxRunCadence),
      'avgPaceS': serializer.toJson<double?>(avgPaceS),
      'bestPaceS': serializer.toJson<double?>(bestPaceS),
      'totalAscent': serializer.toJson<double?>(totalAscent),
      'totalDescent': serializer.toJson<double?>(totalDescent),
      'avgStrideLengthM': serializer.toJson<double?>(avgStrideLengthM),
      'trainingStressScore': serializer.toJson<double?>(trainingStressScore),
      'steps': serializer.toJson<int?>(steps),
      'minTemp': serializer.toJson<double?>(minTemp),
      'maxTemp': serializer.toJson<double?>(maxTemp),
      'decompression': serializer.toJson<String?>(decompression),
      'bestLapTimeS': serializer.toJson<double?>(bestLapTimeS),
      'numberOfLaps': serializer.toJson<int?>(numberOfLaps),
      'minElevation': serializer.toJson<double?>(minElevation),
      'maxElevation': serializer.toJson<double?>(maxElevation),
      'rawMetricsJson': serializer.toJson<String>(rawMetricsJson),
    };
  }

  RunSessionDetail copyWith(
          {String? runSessionId,
          Value<bool?> favorite = const Value.absent(),
          Value<double?> aerobicTe = const Value.absent(),
          Value<double?> avgRunCadence = const Value.absent(),
          Value<double?> maxRunCadence = const Value.absent(),
          Value<double?> avgPaceS = const Value.absent(),
          Value<double?> bestPaceS = const Value.absent(),
          Value<double?> totalAscent = const Value.absent(),
          Value<double?> totalDescent = const Value.absent(),
          Value<double?> avgStrideLengthM = const Value.absent(),
          Value<double?> trainingStressScore = const Value.absent(),
          Value<int?> steps = const Value.absent(),
          Value<double?> minTemp = const Value.absent(),
          Value<double?> maxTemp = const Value.absent(),
          Value<String?> decompression = const Value.absent(),
          Value<double?> bestLapTimeS = const Value.absent(),
          Value<int?> numberOfLaps = const Value.absent(),
          Value<double?> minElevation = const Value.absent(),
          Value<double?> maxElevation = const Value.absent(),
          String? rawMetricsJson}) =>
      RunSessionDetail(
        runSessionId: runSessionId ?? this.runSessionId,
        favorite: favorite.present ? favorite.value : this.favorite,
        aerobicTe: aerobicTe.present ? aerobicTe.value : this.aerobicTe,
        avgRunCadence:
            avgRunCadence.present ? avgRunCadence.value : this.avgRunCadence,
        maxRunCadence:
            maxRunCadence.present ? maxRunCadence.value : this.maxRunCadence,
        avgPaceS: avgPaceS.present ? avgPaceS.value : this.avgPaceS,
        bestPaceS: bestPaceS.present ? bestPaceS.value : this.bestPaceS,
        totalAscent: totalAscent.present ? totalAscent.value : this.totalAscent,
        totalDescent:
            totalDescent.present ? totalDescent.value : this.totalDescent,
        avgStrideLengthM: avgStrideLengthM.present
            ? avgStrideLengthM.value
            : this.avgStrideLengthM,
        trainingStressScore: trainingStressScore.present
            ? trainingStressScore.value
            : this.trainingStressScore,
        steps: steps.present ? steps.value : this.steps,
        minTemp: minTemp.present ? minTemp.value : this.minTemp,
        maxTemp: maxTemp.present ? maxTemp.value : this.maxTemp,
        decompression:
            decompression.present ? decompression.value : this.decompression,
        bestLapTimeS:
            bestLapTimeS.present ? bestLapTimeS.value : this.bestLapTimeS,
        numberOfLaps:
            numberOfLaps.present ? numberOfLaps.value : this.numberOfLaps,
        minElevation:
            minElevation.present ? minElevation.value : this.minElevation,
        maxElevation:
            maxElevation.present ? maxElevation.value : this.maxElevation,
        rawMetricsJson: rawMetricsJson ?? this.rawMetricsJson,
      );
  RunSessionDetail copyWithCompanion(RunSessionDetailsCompanion data) {
    return RunSessionDetail(
      runSessionId: data.runSessionId.present
          ? data.runSessionId.value
          : this.runSessionId,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      aerobicTe: data.aerobicTe.present ? data.aerobicTe.value : this.aerobicTe,
      avgRunCadence: data.avgRunCadence.present
          ? data.avgRunCadence.value
          : this.avgRunCadence,
      maxRunCadence: data.maxRunCadence.present
          ? data.maxRunCadence.value
          : this.maxRunCadence,
      avgPaceS: data.avgPaceS.present ? data.avgPaceS.value : this.avgPaceS,
      bestPaceS: data.bestPaceS.present ? data.bestPaceS.value : this.bestPaceS,
      totalAscent:
          data.totalAscent.present ? data.totalAscent.value : this.totalAscent,
      totalDescent: data.totalDescent.present
          ? data.totalDescent.value
          : this.totalDescent,
      avgStrideLengthM: data.avgStrideLengthM.present
          ? data.avgStrideLengthM.value
          : this.avgStrideLengthM,
      trainingStressScore: data.trainingStressScore.present
          ? data.trainingStressScore.value
          : this.trainingStressScore,
      steps: data.steps.present ? data.steps.value : this.steps,
      minTemp: data.minTemp.present ? data.minTemp.value : this.minTemp,
      maxTemp: data.maxTemp.present ? data.maxTemp.value : this.maxTemp,
      decompression: data.decompression.present
          ? data.decompression.value
          : this.decompression,
      bestLapTimeS: data.bestLapTimeS.present
          ? data.bestLapTimeS.value
          : this.bestLapTimeS,
      numberOfLaps: data.numberOfLaps.present
          ? data.numberOfLaps.value
          : this.numberOfLaps,
      minElevation: data.minElevation.present
          ? data.minElevation.value
          : this.minElevation,
      maxElevation: data.maxElevation.present
          ? data.maxElevation.value
          : this.maxElevation,
      rawMetricsJson: data.rawMetricsJson.present
          ? data.rawMetricsJson.value
          : this.rawMetricsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunSessionDetail(')
          ..write('runSessionId: $runSessionId, ')
          ..write('favorite: $favorite, ')
          ..write('aerobicTe: $aerobicTe, ')
          ..write('avgRunCadence: $avgRunCadence, ')
          ..write('maxRunCadence: $maxRunCadence, ')
          ..write('avgPaceS: $avgPaceS, ')
          ..write('bestPaceS: $bestPaceS, ')
          ..write('totalAscent: $totalAscent, ')
          ..write('totalDescent: $totalDescent, ')
          ..write('avgStrideLengthM: $avgStrideLengthM, ')
          ..write('trainingStressScore: $trainingStressScore, ')
          ..write('steps: $steps, ')
          ..write('minTemp: $minTemp, ')
          ..write('maxTemp: $maxTemp, ')
          ..write('decompression: $decompression, ')
          ..write('bestLapTimeS: $bestLapTimeS, ')
          ..write('numberOfLaps: $numberOfLaps, ')
          ..write('minElevation: $minElevation, ')
          ..write('maxElevation: $maxElevation, ')
          ..write('rawMetricsJson: $rawMetricsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      runSessionId,
      favorite,
      aerobicTe,
      avgRunCadence,
      maxRunCadence,
      avgPaceS,
      bestPaceS,
      totalAscent,
      totalDescent,
      avgStrideLengthM,
      trainingStressScore,
      steps,
      minTemp,
      maxTemp,
      decompression,
      bestLapTimeS,
      numberOfLaps,
      minElevation,
      maxElevation,
      rawMetricsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunSessionDetail &&
          other.runSessionId == this.runSessionId &&
          other.favorite == this.favorite &&
          other.aerobicTe == this.aerobicTe &&
          other.avgRunCadence == this.avgRunCadence &&
          other.maxRunCadence == this.maxRunCadence &&
          other.avgPaceS == this.avgPaceS &&
          other.bestPaceS == this.bestPaceS &&
          other.totalAscent == this.totalAscent &&
          other.totalDescent == this.totalDescent &&
          other.avgStrideLengthM == this.avgStrideLengthM &&
          other.trainingStressScore == this.trainingStressScore &&
          other.steps == this.steps &&
          other.minTemp == this.minTemp &&
          other.maxTemp == this.maxTemp &&
          other.decompression == this.decompression &&
          other.bestLapTimeS == this.bestLapTimeS &&
          other.numberOfLaps == this.numberOfLaps &&
          other.minElevation == this.minElevation &&
          other.maxElevation == this.maxElevation &&
          other.rawMetricsJson == this.rawMetricsJson);
}

class RunSessionDetailsCompanion extends UpdateCompanion<RunSessionDetail> {
  final Value<String> runSessionId;
  final Value<bool?> favorite;
  final Value<double?> aerobicTe;
  final Value<double?> avgRunCadence;
  final Value<double?> maxRunCadence;
  final Value<double?> avgPaceS;
  final Value<double?> bestPaceS;
  final Value<double?> totalAscent;
  final Value<double?> totalDescent;
  final Value<double?> avgStrideLengthM;
  final Value<double?> trainingStressScore;
  final Value<int?> steps;
  final Value<double?> minTemp;
  final Value<double?> maxTemp;
  final Value<String?> decompression;
  final Value<double?> bestLapTimeS;
  final Value<int?> numberOfLaps;
  final Value<double?> minElevation;
  final Value<double?> maxElevation;
  final Value<String> rawMetricsJson;
  final Value<int> rowid;
  const RunSessionDetailsCompanion({
    this.runSessionId = const Value.absent(),
    this.favorite = const Value.absent(),
    this.aerobicTe = const Value.absent(),
    this.avgRunCadence = const Value.absent(),
    this.maxRunCadence = const Value.absent(),
    this.avgPaceS = const Value.absent(),
    this.bestPaceS = const Value.absent(),
    this.totalAscent = const Value.absent(),
    this.totalDescent = const Value.absent(),
    this.avgStrideLengthM = const Value.absent(),
    this.trainingStressScore = const Value.absent(),
    this.steps = const Value.absent(),
    this.minTemp = const Value.absent(),
    this.maxTemp = const Value.absent(),
    this.decompression = const Value.absent(),
    this.bestLapTimeS = const Value.absent(),
    this.numberOfLaps = const Value.absent(),
    this.minElevation = const Value.absent(),
    this.maxElevation = const Value.absent(),
    this.rawMetricsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunSessionDetailsCompanion.insert({
    required String runSessionId,
    this.favorite = const Value.absent(),
    this.aerobicTe = const Value.absent(),
    this.avgRunCadence = const Value.absent(),
    this.maxRunCadence = const Value.absent(),
    this.avgPaceS = const Value.absent(),
    this.bestPaceS = const Value.absent(),
    this.totalAscent = const Value.absent(),
    this.totalDescent = const Value.absent(),
    this.avgStrideLengthM = const Value.absent(),
    this.trainingStressScore = const Value.absent(),
    this.steps = const Value.absent(),
    this.minTemp = const Value.absent(),
    this.maxTemp = const Value.absent(),
    this.decompression = const Value.absent(),
    this.bestLapTimeS = const Value.absent(),
    this.numberOfLaps = const Value.absent(),
    this.minElevation = const Value.absent(),
    this.maxElevation = const Value.absent(),
    required String rawMetricsJson,
    this.rowid = const Value.absent(),
  })  : runSessionId = Value(runSessionId),
        rawMetricsJson = Value(rawMetricsJson);
  static Insertable<RunSessionDetail> custom({
    Expression<String>? runSessionId,
    Expression<bool>? favorite,
    Expression<double>? aerobicTe,
    Expression<double>? avgRunCadence,
    Expression<double>? maxRunCadence,
    Expression<double>? avgPaceS,
    Expression<double>? bestPaceS,
    Expression<double>? totalAscent,
    Expression<double>? totalDescent,
    Expression<double>? avgStrideLengthM,
    Expression<double>? trainingStressScore,
    Expression<int>? steps,
    Expression<double>? minTemp,
    Expression<double>? maxTemp,
    Expression<String>? decompression,
    Expression<double>? bestLapTimeS,
    Expression<int>? numberOfLaps,
    Expression<double>? minElevation,
    Expression<double>? maxElevation,
    Expression<String>? rawMetricsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runSessionId != null) 'run_session_id': runSessionId,
      if (favorite != null) 'favorite': favorite,
      if (aerobicTe != null) 'aerobic_te': aerobicTe,
      if (avgRunCadence != null) 'avg_run_cadence': avgRunCadence,
      if (maxRunCadence != null) 'max_run_cadence': maxRunCadence,
      if (avgPaceS != null) 'avg_pace_s': avgPaceS,
      if (bestPaceS != null) 'best_pace_s': bestPaceS,
      if (totalAscent != null) 'total_ascent': totalAscent,
      if (totalDescent != null) 'total_descent': totalDescent,
      if (avgStrideLengthM != null) 'avg_stride_length_m': avgStrideLengthM,
      if (trainingStressScore != null)
        'training_stress_score': trainingStressScore,
      if (steps != null) 'steps': steps,
      if (minTemp != null) 'min_temp': minTemp,
      if (maxTemp != null) 'max_temp': maxTemp,
      if (decompression != null) 'decompression': decompression,
      if (bestLapTimeS != null) 'best_lap_time_s': bestLapTimeS,
      if (numberOfLaps != null) 'number_of_laps': numberOfLaps,
      if (minElevation != null) 'min_elevation': minElevation,
      if (maxElevation != null) 'max_elevation': maxElevation,
      if (rawMetricsJson != null) 'raw_metrics_json': rawMetricsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunSessionDetailsCompanion copyWith(
      {Value<String>? runSessionId,
      Value<bool?>? favorite,
      Value<double?>? aerobicTe,
      Value<double?>? avgRunCadence,
      Value<double?>? maxRunCadence,
      Value<double?>? avgPaceS,
      Value<double?>? bestPaceS,
      Value<double?>? totalAscent,
      Value<double?>? totalDescent,
      Value<double?>? avgStrideLengthM,
      Value<double?>? trainingStressScore,
      Value<int?>? steps,
      Value<double?>? minTemp,
      Value<double?>? maxTemp,
      Value<String?>? decompression,
      Value<double?>? bestLapTimeS,
      Value<int?>? numberOfLaps,
      Value<double?>? minElevation,
      Value<double?>? maxElevation,
      Value<String>? rawMetricsJson,
      Value<int>? rowid}) {
    return RunSessionDetailsCompanion(
      runSessionId: runSessionId ?? this.runSessionId,
      favorite: favorite ?? this.favorite,
      aerobicTe: aerobicTe ?? this.aerobicTe,
      avgRunCadence: avgRunCadence ?? this.avgRunCadence,
      maxRunCadence: maxRunCadence ?? this.maxRunCadence,
      avgPaceS: avgPaceS ?? this.avgPaceS,
      bestPaceS: bestPaceS ?? this.bestPaceS,
      totalAscent: totalAscent ?? this.totalAscent,
      totalDescent: totalDescent ?? this.totalDescent,
      avgStrideLengthM: avgStrideLengthM ?? this.avgStrideLengthM,
      trainingStressScore: trainingStressScore ?? this.trainingStressScore,
      steps: steps ?? this.steps,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      decompression: decompression ?? this.decompression,
      bestLapTimeS: bestLapTimeS ?? this.bestLapTimeS,
      numberOfLaps: numberOfLaps ?? this.numberOfLaps,
      minElevation: minElevation ?? this.minElevation,
      maxElevation: maxElevation ?? this.maxElevation,
      rawMetricsJson: rawMetricsJson ?? this.rawMetricsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runSessionId.present) {
      map['run_session_id'] = Variable<String>(runSessionId.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (aerobicTe.present) {
      map['aerobic_te'] = Variable<double>(aerobicTe.value);
    }
    if (avgRunCadence.present) {
      map['avg_run_cadence'] = Variable<double>(avgRunCadence.value);
    }
    if (maxRunCadence.present) {
      map['max_run_cadence'] = Variable<double>(maxRunCadence.value);
    }
    if (avgPaceS.present) {
      map['avg_pace_s'] = Variable<double>(avgPaceS.value);
    }
    if (bestPaceS.present) {
      map['best_pace_s'] = Variable<double>(bestPaceS.value);
    }
    if (totalAscent.present) {
      map['total_ascent'] = Variable<double>(totalAscent.value);
    }
    if (totalDescent.present) {
      map['total_descent'] = Variable<double>(totalDescent.value);
    }
    if (avgStrideLengthM.present) {
      map['avg_stride_length_m'] = Variable<double>(avgStrideLengthM.value);
    }
    if (trainingStressScore.present) {
      map['training_stress_score'] =
          Variable<double>(trainingStressScore.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (minTemp.present) {
      map['min_temp'] = Variable<double>(minTemp.value);
    }
    if (maxTemp.present) {
      map['max_temp'] = Variable<double>(maxTemp.value);
    }
    if (decompression.present) {
      map['decompression'] = Variable<String>(decompression.value);
    }
    if (bestLapTimeS.present) {
      map['best_lap_time_s'] = Variable<double>(bestLapTimeS.value);
    }
    if (numberOfLaps.present) {
      map['number_of_laps'] = Variable<int>(numberOfLaps.value);
    }
    if (minElevation.present) {
      map['min_elevation'] = Variable<double>(minElevation.value);
    }
    if (maxElevation.present) {
      map['max_elevation'] = Variable<double>(maxElevation.value);
    }
    if (rawMetricsJson.present) {
      map['raw_metrics_json'] = Variable<String>(rawMetricsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunSessionDetailsCompanion(')
          ..write('runSessionId: $runSessionId, ')
          ..write('favorite: $favorite, ')
          ..write('aerobicTe: $aerobicTe, ')
          ..write('avgRunCadence: $avgRunCadence, ')
          ..write('maxRunCadence: $maxRunCadence, ')
          ..write('avgPaceS: $avgPaceS, ')
          ..write('bestPaceS: $bestPaceS, ')
          ..write('totalAscent: $totalAscent, ')
          ..write('totalDescent: $totalDescent, ')
          ..write('avgStrideLengthM: $avgStrideLengthM, ')
          ..write('trainingStressScore: $trainingStressScore, ')
          ..write('steps: $steps, ')
          ..write('minTemp: $minTemp, ')
          ..write('maxTemp: $maxTemp, ')
          ..write('decompression: $decompression, ')
          ..write('bestLapTimeS: $bestLapTimeS, ')
          ..write('numberOfLaps: $numberOfLaps, ')
          ..write('minElevation: $minElevation, ')
          ..write('maxElevation: $maxElevation, ')
          ..write('rawMetricsJson: $rawMetricsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunOverrideAuditTable extends RunOverrideAudit
    with TableInfo<$RunOverrideAuditTable, RunOverrideAuditData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunOverrideAuditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runKeyMeta = const VerificationMeta('runKey');
  @override
  late final GeneratedColumn<String> runKey = GeneratedColumn<String>(
      'run_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutDayIdMeta =
      const VerificationMeta('workoutDayId');
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
      'workout_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oldSourceMeta =
      const VerificationMeta('oldSource');
  @override
  late final GeneratedColumn<String> oldSource = GeneratedColumn<String>(
      'old_source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newSourceMeta =
      const VerificationMeta('newSource');
  @override
  late final GeneratedColumn<String> newSource = GeneratedColumn<String>(
      'new_source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _oldSnapshotJsonMeta =
      const VerificationMeta('oldSnapshotJson');
  @override
  late final GeneratedColumn<String> oldSnapshotJson = GeneratedColumn<String>(
      'old_snapshot_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newSnapshotJsonMeta =
      const VerificationMeta('newSnapshotJson');
  @override
  late final GeneratedColumn<String> newSnapshotJson = GeneratedColumn<String>(
      'new_snapshot_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        runKey,
        workoutDayId,
        oldSource,
        newSource,
        oldSnapshotJson,
        newSnapshotJson,
        reason,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_override_audit';
  @override
  VerificationContext validateIntegrity(
      Insertable<RunOverrideAuditData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_key')) {
      context.handle(_runKeyMeta,
          runKey.isAcceptableOrUnknown(data['run_key']!, _runKeyMeta));
    } else if (isInserting) {
      context.missing(_runKeyMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
          _workoutDayIdMeta,
          workoutDayId.isAcceptableOrUnknown(
              data['workout_day_id']!, _workoutDayIdMeta));
    }
    if (data.containsKey('old_source')) {
      context.handle(_oldSourceMeta,
          oldSource.isAcceptableOrUnknown(data['old_source']!, _oldSourceMeta));
    } else if (isInserting) {
      context.missing(_oldSourceMeta);
    }
    if (data.containsKey('new_source')) {
      context.handle(_newSourceMeta,
          newSource.isAcceptableOrUnknown(data['new_source']!, _newSourceMeta));
    } else if (isInserting) {
      context.missing(_newSourceMeta);
    }
    if (data.containsKey('old_snapshot_json')) {
      context.handle(
          _oldSnapshotJsonMeta,
          oldSnapshotJson.isAcceptableOrUnknown(
              data['old_snapshot_json']!, _oldSnapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_oldSnapshotJsonMeta);
    }
    if (data.containsKey('new_snapshot_json')) {
      context.handle(
          _newSnapshotJsonMeta,
          newSnapshotJson.isAcceptableOrUnknown(
              data['new_snapshot_json']!, _newSnapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_newSnapshotJsonMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunOverrideAuditData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunOverrideAuditData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      runKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_key'])!,
      workoutDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_day_id']),
      oldSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_source'])!,
      newSource: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_source'])!,
      oldSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}old_snapshot_json'])!,
      newSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}new_snapshot_json'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RunOverrideAuditTable createAlias(String alias) {
    return $RunOverrideAuditTable(attachedDatabase, alias);
  }
}

class RunOverrideAuditData extends DataClass
    implements Insertable<RunOverrideAuditData> {
  final String id;
  final String runKey;
  final String? workoutDayId;
  final String oldSource;
  final String newSource;
  final String oldSnapshotJson;
  final String newSnapshotJson;
  final String reason;
  final int createdAt;
  const RunOverrideAuditData(
      {required this.id,
      required this.runKey,
      this.workoutDayId,
      required this.oldSource,
      required this.newSource,
      required this.oldSnapshotJson,
      required this.newSnapshotJson,
      required this.reason,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_key'] = Variable<String>(runKey);
    if (!nullToAbsent || workoutDayId != null) {
      map['workout_day_id'] = Variable<String>(workoutDayId);
    }
    map['old_source'] = Variable<String>(oldSource);
    map['new_source'] = Variable<String>(newSource);
    map['old_snapshot_json'] = Variable<String>(oldSnapshotJson);
    map['new_snapshot_json'] = Variable<String>(newSnapshotJson);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RunOverrideAuditCompanion toCompanion(bool nullToAbsent) {
    return RunOverrideAuditCompanion(
      id: Value(id),
      runKey: Value(runKey),
      workoutDayId: workoutDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutDayId),
      oldSource: Value(oldSource),
      newSource: Value(newSource),
      oldSnapshotJson: Value(oldSnapshotJson),
      newSnapshotJson: Value(newSnapshotJson),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory RunOverrideAuditData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunOverrideAuditData(
      id: serializer.fromJson<String>(json['id']),
      runKey: serializer.fromJson<String>(json['runKey']),
      workoutDayId: serializer.fromJson<String?>(json['workoutDayId']),
      oldSource: serializer.fromJson<String>(json['oldSource']),
      newSource: serializer.fromJson<String>(json['newSource']),
      oldSnapshotJson: serializer.fromJson<String>(json['oldSnapshotJson']),
      newSnapshotJson: serializer.fromJson<String>(json['newSnapshotJson']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runKey': serializer.toJson<String>(runKey),
      'workoutDayId': serializer.toJson<String?>(workoutDayId),
      'oldSource': serializer.toJson<String>(oldSource),
      'newSource': serializer.toJson<String>(newSource),
      'oldSnapshotJson': serializer.toJson<String>(oldSnapshotJson),
      'newSnapshotJson': serializer.toJson<String>(newSnapshotJson),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RunOverrideAuditData copyWith(
          {String? id,
          String? runKey,
          Value<String?> workoutDayId = const Value.absent(),
          String? oldSource,
          String? newSource,
          String? oldSnapshotJson,
          String? newSnapshotJson,
          String? reason,
          int? createdAt}) =>
      RunOverrideAuditData(
        id: id ?? this.id,
        runKey: runKey ?? this.runKey,
        workoutDayId:
            workoutDayId.present ? workoutDayId.value : this.workoutDayId,
        oldSource: oldSource ?? this.oldSource,
        newSource: newSource ?? this.newSource,
        oldSnapshotJson: oldSnapshotJson ?? this.oldSnapshotJson,
        newSnapshotJson: newSnapshotJson ?? this.newSnapshotJson,
        reason: reason ?? this.reason,
        createdAt: createdAt ?? this.createdAt,
      );
  RunOverrideAuditData copyWithCompanion(RunOverrideAuditCompanion data) {
    return RunOverrideAuditData(
      id: data.id.present ? data.id.value : this.id,
      runKey: data.runKey.present ? data.runKey.value : this.runKey,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      oldSource: data.oldSource.present ? data.oldSource.value : this.oldSource,
      newSource: data.newSource.present ? data.newSource.value : this.newSource,
      oldSnapshotJson: data.oldSnapshotJson.present
          ? data.oldSnapshotJson.value
          : this.oldSnapshotJson,
      newSnapshotJson: data.newSnapshotJson.present
          ? data.newSnapshotJson.value
          : this.newSnapshotJson,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunOverrideAuditData(')
          ..write('id: $id, ')
          ..write('runKey: $runKey, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('oldSource: $oldSource, ')
          ..write('newSource: $newSource, ')
          ..write('oldSnapshotJson: $oldSnapshotJson, ')
          ..write('newSnapshotJson: $newSnapshotJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, runKey, workoutDayId, oldSource,
      newSource, oldSnapshotJson, newSnapshotJson, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunOverrideAuditData &&
          other.id == this.id &&
          other.runKey == this.runKey &&
          other.workoutDayId == this.workoutDayId &&
          other.oldSource == this.oldSource &&
          other.newSource == this.newSource &&
          other.oldSnapshotJson == this.oldSnapshotJson &&
          other.newSnapshotJson == this.newSnapshotJson &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class RunOverrideAuditCompanion extends UpdateCompanion<RunOverrideAuditData> {
  final Value<String> id;
  final Value<String> runKey;
  final Value<String?> workoutDayId;
  final Value<String> oldSource;
  final Value<String> newSource;
  final Value<String> oldSnapshotJson;
  final Value<String> newSnapshotJson;
  final Value<String> reason;
  final Value<int> createdAt;
  final Value<int> rowid;
  const RunOverrideAuditCompanion({
    this.id = const Value.absent(),
    this.runKey = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.oldSource = const Value.absent(),
    this.newSource = const Value.absent(),
    this.oldSnapshotJson = const Value.absent(),
    this.newSnapshotJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunOverrideAuditCompanion.insert({
    required String id,
    required String runKey,
    this.workoutDayId = const Value.absent(),
    required String oldSource,
    required String newSource,
    required String oldSnapshotJson,
    required String newSnapshotJson,
    required String reason,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        runKey = Value(runKey),
        oldSource = Value(oldSource),
        newSource = Value(newSource),
        oldSnapshotJson = Value(oldSnapshotJson),
        newSnapshotJson = Value(newSnapshotJson),
        reason = Value(reason),
        createdAt = Value(createdAt);
  static Insertable<RunOverrideAuditData> custom({
    Expression<String>? id,
    Expression<String>? runKey,
    Expression<String>? workoutDayId,
    Expression<String>? oldSource,
    Expression<String>? newSource,
    Expression<String>? oldSnapshotJson,
    Expression<String>? newSnapshotJson,
    Expression<String>? reason,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runKey != null) 'run_key': runKey,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (oldSource != null) 'old_source': oldSource,
      if (newSource != null) 'new_source': newSource,
      if (oldSnapshotJson != null) 'old_snapshot_json': oldSnapshotJson,
      if (newSnapshotJson != null) 'new_snapshot_json': newSnapshotJson,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunOverrideAuditCompanion copyWith(
      {Value<String>? id,
      Value<String>? runKey,
      Value<String?>? workoutDayId,
      Value<String>? oldSource,
      Value<String>? newSource,
      Value<String>? oldSnapshotJson,
      Value<String>? newSnapshotJson,
      Value<String>? reason,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return RunOverrideAuditCompanion(
      id: id ?? this.id,
      runKey: runKey ?? this.runKey,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      oldSource: oldSource ?? this.oldSource,
      newSource: newSource ?? this.newSource,
      oldSnapshotJson: oldSnapshotJson ?? this.oldSnapshotJson,
      newSnapshotJson: newSnapshotJson ?? this.newSnapshotJson,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runKey.present) {
      map['run_key'] = Variable<String>(runKey.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (oldSource.present) {
      map['old_source'] = Variable<String>(oldSource.value);
    }
    if (newSource.present) {
      map['new_source'] = Variable<String>(newSource.value);
    }
    if (oldSnapshotJson.present) {
      map['old_snapshot_json'] = Variable<String>(oldSnapshotJson.value);
    }
    if (newSnapshotJson.present) {
      map['new_snapshot_json'] = Variable<String>(newSnapshotJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunOverrideAuditCompanion(')
          ..write('id: $id, ')
          ..write('runKey: $runKey, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('oldSource: $oldSource, ')
          ..write('newSource: $newSource, ')
          ..write('oldSnapshotJson: $oldSnapshotJson, ')
          ..write('newSnapshotJson: $newSnapshotJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleTriggersTable extends RuleTriggers
    with TableInfo<$RuleTriggersTable, RuleTrigger> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleTriggersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _triggerDateMeta =
      const VerificationMeta('triggerDate');
  @override
  late final GeneratedColumn<String> triggerDate = GeneratedColumn<String>(
      'trigger_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ruleCodeMeta =
      const VerificationMeta('ruleCode');
  @override
  late final GeneratedColumn<String> ruleCode = GeneratedColumn<String>(
      'rule_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _triggeredMeta =
      const VerificationMeta('triggered');
  @override
  late final GeneratedColumn<bool> triggered = GeneratedColumn<bool>(
      'triggered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("triggered" IN (0, 1))'));
  static const VerificationMeta _detailsJsonMeta =
      const VerificationMeta('detailsJson');
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
      'details_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, triggerDate, ruleCode, triggered, detailsJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_triggers';
  @override
  VerificationContext validateIntegrity(Insertable<RuleTrigger> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trigger_date')) {
      context.handle(
          _triggerDateMeta,
          triggerDate.isAcceptableOrUnknown(
              data['trigger_date']!, _triggerDateMeta));
    } else if (isInserting) {
      context.missing(_triggerDateMeta);
    }
    if (data.containsKey('rule_code')) {
      context.handle(_ruleCodeMeta,
          ruleCode.isAcceptableOrUnknown(data['rule_code']!, _ruleCodeMeta));
    } else if (isInserting) {
      context.missing(_ruleCodeMeta);
    }
    if (data.containsKey('triggered')) {
      context.handle(_triggeredMeta,
          triggered.isAcceptableOrUnknown(data['triggered']!, _triggeredMeta));
    } else if (isInserting) {
      context.missing(_triggeredMeta);
    }
    if (data.containsKey('details_json')) {
      context.handle(
          _detailsJsonMeta,
          detailsJson.isAcceptableOrUnknown(
              data['details_json']!, _detailsJsonMeta));
    } else if (isInserting) {
      context.missing(_detailsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleTrigger map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleTrigger(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      triggerDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger_date'])!,
      ruleCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rule_code'])!,
      triggered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}triggered'])!,
      detailsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RuleTriggersTable createAlias(String alias) {
    return $RuleTriggersTable(attachedDatabase, alias);
  }
}

class RuleTrigger extends DataClass implements Insertable<RuleTrigger> {
  final String id;
  final String triggerDate;
  final String ruleCode;
  final bool triggered;
  final String detailsJson;
  final int createdAt;
  const RuleTrigger(
      {required this.id,
      required this.triggerDate,
      required this.ruleCode,
      required this.triggered,
      required this.detailsJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trigger_date'] = Variable<String>(triggerDate);
    map['rule_code'] = Variable<String>(ruleCode);
    map['triggered'] = Variable<bool>(triggered);
    map['details_json'] = Variable<String>(detailsJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RuleTriggersCompanion toCompanion(bool nullToAbsent) {
    return RuleTriggersCompanion(
      id: Value(id),
      triggerDate: Value(triggerDate),
      ruleCode: Value(ruleCode),
      triggered: Value(triggered),
      detailsJson: Value(detailsJson),
      createdAt: Value(createdAt),
    );
  }

  factory RuleTrigger.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleTrigger(
      id: serializer.fromJson<String>(json['id']),
      triggerDate: serializer.fromJson<String>(json['triggerDate']),
      ruleCode: serializer.fromJson<String>(json['ruleCode']),
      triggered: serializer.fromJson<bool>(json['triggered']),
      detailsJson: serializer.fromJson<String>(json['detailsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'triggerDate': serializer.toJson<String>(triggerDate),
      'ruleCode': serializer.toJson<String>(ruleCode),
      'triggered': serializer.toJson<bool>(triggered),
      'detailsJson': serializer.toJson<String>(detailsJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RuleTrigger copyWith(
          {String? id,
          String? triggerDate,
          String? ruleCode,
          bool? triggered,
          String? detailsJson,
          int? createdAt}) =>
      RuleTrigger(
        id: id ?? this.id,
        triggerDate: triggerDate ?? this.triggerDate,
        ruleCode: ruleCode ?? this.ruleCode,
        triggered: triggered ?? this.triggered,
        detailsJson: detailsJson ?? this.detailsJson,
        createdAt: createdAt ?? this.createdAt,
      );
  RuleTrigger copyWithCompanion(RuleTriggersCompanion data) {
    return RuleTrigger(
      id: data.id.present ? data.id.value : this.id,
      triggerDate:
          data.triggerDate.present ? data.triggerDate.value : this.triggerDate,
      ruleCode: data.ruleCode.present ? data.ruleCode.value : this.ruleCode,
      triggered: data.triggered.present ? data.triggered.value : this.triggered,
      detailsJson:
          data.detailsJson.present ? data.detailsJson.value : this.detailsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleTrigger(')
          ..write('id: $id, ')
          ..write('triggerDate: $triggerDate, ')
          ..write('ruleCode: $ruleCode, ')
          ..write('triggered: $triggered, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, triggerDate, ruleCode, triggered, detailsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleTrigger &&
          other.id == this.id &&
          other.triggerDate == this.triggerDate &&
          other.ruleCode == this.ruleCode &&
          other.triggered == this.triggered &&
          other.detailsJson == this.detailsJson &&
          other.createdAt == this.createdAt);
}

class RuleTriggersCompanion extends UpdateCompanion<RuleTrigger> {
  final Value<String> id;
  final Value<String> triggerDate;
  final Value<String> ruleCode;
  final Value<bool> triggered;
  final Value<String> detailsJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const RuleTriggersCompanion({
    this.id = const Value.absent(),
    this.triggerDate = const Value.absent(),
    this.ruleCode = const Value.absent(),
    this.triggered = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleTriggersCompanion.insert({
    required String id,
    required String triggerDate,
    required String ruleCode,
    required bool triggered,
    required String detailsJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        triggerDate = Value(triggerDate),
        ruleCode = Value(ruleCode),
        triggered = Value(triggered),
        detailsJson = Value(detailsJson),
        createdAt = Value(createdAt);
  static Insertable<RuleTrigger> custom({
    Expression<String>? id,
    Expression<String>? triggerDate,
    Expression<String>? ruleCode,
    Expression<bool>? triggered,
    Expression<String>? detailsJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (triggerDate != null) 'trigger_date': triggerDate,
      if (ruleCode != null) 'rule_code': ruleCode,
      if (triggered != null) 'triggered': triggered,
      if (detailsJson != null) 'details_json': detailsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleTriggersCompanion copyWith(
      {Value<String>? id,
      Value<String>? triggerDate,
      Value<String>? ruleCode,
      Value<bool>? triggered,
      Value<String>? detailsJson,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return RuleTriggersCompanion(
      id: id ?? this.id,
      triggerDate: triggerDate ?? this.triggerDate,
      ruleCode: ruleCode ?? this.ruleCode,
      triggered: triggered ?? this.triggered,
      detailsJson: detailsJson ?? this.detailsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (triggerDate.present) {
      map['trigger_date'] = Variable<String>(triggerDate.value);
    }
    if (ruleCode.present) {
      map['rule_code'] = Variable<String>(ruleCode.value);
    }
    if (triggered.present) {
      map['triggered'] = Variable<bool>(triggered.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleTriggersCompanion(')
          ..write('id: $id, ')
          ..write('triggerDate: $triggerDate, ')
          ..write('ruleCode: $ruleCode, ')
          ..write('triggered: $triggered, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiAuditTable extends AiAudit with TableInfo<$AiAuditTable, AiAuditData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiAuditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestedAtMeta =
      const VerificationMeta('requestedAt');
  @override
  late final GeneratedColumn<int> requestedAt = GeneratedColumn<int>(
      'requested_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateWindowStartMeta =
      const VerificationMeta('dateWindowStart');
  @override
  late final GeneratedColumn<String> dateWindowStart = GeneratedColumn<String>(
      'date_window_start', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateWindowEndMeta =
      const VerificationMeta('dateWindowEnd');
  @override
  late final GeneratedColumn<String> dateWindowEnd = GeneratedColumn<String>(
      'date_window_end', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _inputSnapshotJsonMeta =
      const VerificationMeta('inputSnapshotJson');
  @override
  late final GeneratedColumn<String> inputSnapshotJson =
      GeneratedColumn<String>('input_snapshot_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseJsonMeta =
      const VerificationMeta('responseJson');
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
      'response_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schemaValidMeta =
      const VerificationMeta('schemaValid');
  @override
  late final GeneratedColumn<bool> schemaValid = GeneratedColumn<bool>(
      'schema_valid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("schema_valid" IN (0, 1))'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        requestedAt,
        dateWindowStart,
        dateWindowEnd,
        inputSnapshotJson,
        responseJson,
        schemaValid,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_audit';
  @override
  VerificationContext validateIntegrity(Insertable<AiAuditData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
          _requestedAtMeta,
          requestedAt.isAcceptableOrUnknown(
              data['requested_at']!, _requestedAtMeta));
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('date_window_start')) {
      context.handle(
          _dateWindowStartMeta,
          dateWindowStart.isAcceptableOrUnknown(
              data['date_window_start']!, _dateWindowStartMeta));
    }
    if (data.containsKey('date_window_end')) {
      context.handle(
          _dateWindowEndMeta,
          dateWindowEnd.isAcceptableOrUnknown(
              data['date_window_end']!, _dateWindowEndMeta));
    }
    if (data.containsKey('input_snapshot_json')) {
      context.handle(
          _inputSnapshotJsonMeta,
          inputSnapshotJson.isAcceptableOrUnknown(
              data['input_snapshot_json']!, _inputSnapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_inputSnapshotJsonMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
          _responseJsonMeta,
          responseJson.isAcceptableOrUnknown(
              data['response_json']!, _responseJsonMeta));
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('schema_valid')) {
      context.handle(
          _schemaValidMeta,
          schemaValid.isAcceptableOrUnknown(
              data['schema_valid']!, _schemaValidMeta));
    } else if (isInserting) {
      context.missing(_schemaValidMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiAuditData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiAuditData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      requestedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}requested_at'])!,
      dateWindowStart: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}date_window_start']),
      dateWindowEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_window_end']),
      inputSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}input_snapshot_json'])!,
      responseJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response_json'])!,
      schemaValid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}schema_valid'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $AiAuditTable createAlias(String alias) {
    return $AiAuditTable(attachedDatabase, alias);
  }
}

class AiAuditData extends DataClass implements Insertable<AiAuditData> {
  final String id;
  final int requestedAt;
  final String? dateWindowStart;
  final String? dateWindowEnd;
  final String inputSnapshotJson;
  final String responseJson;
  final bool schemaValid;
  final String? notes;
  const AiAuditData(
      {required this.id,
      required this.requestedAt,
      this.dateWindowStart,
      this.dateWindowEnd,
      required this.inputSnapshotJson,
      required this.responseJson,
      required this.schemaValid,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['requested_at'] = Variable<int>(requestedAt);
    if (!nullToAbsent || dateWindowStart != null) {
      map['date_window_start'] = Variable<String>(dateWindowStart);
    }
    if (!nullToAbsent || dateWindowEnd != null) {
      map['date_window_end'] = Variable<String>(dateWindowEnd);
    }
    map['input_snapshot_json'] = Variable<String>(inputSnapshotJson);
    map['response_json'] = Variable<String>(responseJson);
    map['schema_valid'] = Variable<bool>(schemaValid);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AiAuditCompanion toCompanion(bool nullToAbsent) {
    return AiAuditCompanion(
      id: Value(id),
      requestedAt: Value(requestedAt),
      dateWindowStart: dateWindowStart == null && nullToAbsent
          ? const Value.absent()
          : Value(dateWindowStart),
      dateWindowEnd: dateWindowEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(dateWindowEnd),
      inputSnapshotJson: Value(inputSnapshotJson),
      responseJson: Value(responseJson),
      schemaValid: Value(schemaValid),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory AiAuditData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiAuditData(
      id: serializer.fromJson<String>(json['id']),
      requestedAt: serializer.fromJson<int>(json['requestedAt']),
      dateWindowStart: serializer.fromJson<String?>(json['dateWindowStart']),
      dateWindowEnd: serializer.fromJson<String?>(json['dateWindowEnd']),
      inputSnapshotJson: serializer.fromJson<String>(json['inputSnapshotJson']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      schemaValid: serializer.fromJson<bool>(json['schemaValid']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'requestedAt': serializer.toJson<int>(requestedAt),
      'dateWindowStart': serializer.toJson<String?>(dateWindowStart),
      'dateWindowEnd': serializer.toJson<String?>(dateWindowEnd),
      'inputSnapshotJson': serializer.toJson<String>(inputSnapshotJson),
      'responseJson': serializer.toJson<String>(responseJson),
      'schemaValid': serializer.toJson<bool>(schemaValid),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AiAuditData copyWith(
          {String? id,
          int? requestedAt,
          Value<String?> dateWindowStart = const Value.absent(),
          Value<String?> dateWindowEnd = const Value.absent(),
          String? inputSnapshotJson,
          String? responseJson,
          bool? schemaValid,
          Value<String?> notes = const Value.absent()}) =>
      AiAuditData(
        id: id ?? this.id,
        requestedAt: requestedAt ?? this.requestedAt,
        dateWindowStart: dateWindowStart.present
            ? dateWindowStart.value
            : this.dateWindowStart,
        dateWindowEnd:
            dateWindowEnd.present ? dateWindowEnd.value : this.dateWindowEnd,
        inputSnapshotJson: inputSnapshotJson ?? this.inputSnapshotJson,
        responseJson: responseJson ?? this.responseJson,
        schemaValid: schemaValid ?? this.schemaValid,
        notes: notes.present ? notes.value : this.notes,
      );
  AiAuditData copyWithCompanion(AiAuditCompanion data) {
    return AiAuditData(
      id: data.id.present ? data.id.value : this.id,
      requestedAt:
          data.requestedAt.present ? data.requestedAt.value : this.requestedAt,
      dateWindowStart: data.dateWindowStart.present
          ? data.dateWindowStart.value
          : this.dateWindowStart,
      dateWindowEnd: data.dateWindowEnd.present
          ? data.dateWindowEnd.value
          : this.dateWindowEnd,
      inputSnapshotJson: data.inputSnapshotJson.present
          ? data.inputSnapshotJson.value
          : this.inputSnapshotJson,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      schemaValid:
          data.schemaValid.present ? data.schemaValid.value : this.schemaValid,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiAuditData(')
          ..write('id: $id, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('dateWindowStart: $dateWindowStart, ')
          ..write('dateWindowEnd: $dateWindowEnd, ')
          ..write('inputSnapshotJson: $inputSnapshotJson, ')
          ..write('responseJson: $responseJson, ')
          ..write('schemaValid: $schemaValid, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, requestedAt, dateWindowStart,
      dateWindowEnd, inputSnapshotJson, responseJson, schemaValid, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiAuditData &&
          other.id == this.id &&
          other.requestedAt == this.requestedAt &&
          other.dateWindowStart == this.dateWindowStart &&
          other.dateWindowEnd == this.dateWindowEnd &&
          other.inputSnapshotJson == this.inputSnapshotJson &&
          other.responseJson == this.responseJson &&
          other.schemaValid == this.schemaValid &&
          other.notes == this.notes);
}

class AiAuditCompanion extends UpdateCompanion<AiAuditData> {
  final Value<String> id;
  final Value<int> requestedAt;
  final Value<String?> dateWindowStart;
  final Value<String?> dateWindowEnd;
  final Value<String> inputSnapshotJson;
  final Value<String> responseJson;
  final Value<bool> schemaValid;
  final Value<String?> notes;
  final Value<int> rowid;
  const AiAuditCompanion({
    this.id = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.dateWindowStart = const Value.absent(),
    this.dateWindowEnd = const Value.absent(),
    this.inputSnapshotJson = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.schemaValid = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiAuditCompanion.insert({
    required String id,
    required int requestedAt,
    this.dateWindowStart = const Value.absent(),
    this.dateWindowEnd = const Value.absent(),
    required String inputSnapshotJson,
    required String responseJson,
    required bool schemaValid,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        requestedAt = Value(requestedAt),
        inputSnapshotJson = Value(inputSnapshotJson),
        responseJson = Value(responseJson),
        schemaValid = Value(schemaValid);
  static Insertable<AiAuditData> custom({
    Expression<String>? id,
    Expression<int>? requestedAt,
    Expression<String>? dateWindowStart,
    Expression<String>? dateWindowEnd,
    Expression<String>? inputSnapshotJson,
    Expression<String>? responseJson,
    Expression<bool>? schemaValid,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (dateWindowStart != null) 'date_window_start': dateWindowStart,
      if (dateWindowEnd != null) 'date_window_end': dateWindowEnd,
      if (inputSnapshotJson != null) 'input_snapshot_json': inputSnapshotJson,
      if (responseJson != null) 'response_json': responseJson,
      if (schemaValid != null) 'schema_valid': schemaValid,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiAuditCompanion copyWith(
      {Value<String>? id,
      Value<int>? requestedAt,
      Value<String?>? dateWindowStart,
      Value<String?>? dateWindowEnd,
      Value<String>? inputSnapshotJson,
      Value<String>? responseJson,
      Value<bool>? schemaValid,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return AiAuditCompanion(
      id: id ?? this.id,
      requestedAt: requestedAt ?? this.requestedAt,
      dateWindowStart: dateWindowStart ?? this.dateWindowStart,
      dateWindowEnd: dateWindowEnd ?? this.dateWindowEnd,
      inputSnapshotJson: inputSnapshotJson ?? this.inputSnapshotJson,
      responseJson: responseJson ?? this.responseJson,
      schemaValid: schemaValid ?? this.schemaValid,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<int>(requestedAt.value);
    }
    if (dateWindowStart.present) {
      map['date_window_start'] = Variable<String>(dateWindowStart.value);
    }
    if (dateWindowEnd.present) {
      map['date_window_end'] = Variable<String>(dateWindowEnd.value);
    }
    if (inputSnapshotJson.present) {
      map['input_snapshot_json'] = Variable<String>(inputSnapshotJson.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (schemaValid.present) {
      map['schema_valid'] = Variable<bool>(schemaValid.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiAuditCompanion(')
          ..write('id: $id, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('dateWindowStart: $dateWindowStart, ')
          ..write('dateWindowEnd: $dateWindowEnd, ')
          ..write('inputSnapshotJson: $inputSnapshotJson, ')
          ..write('responseJson: $responseJson, ')
          ..write('schemaValid: $schemaValid, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseSubstitutionsTable extends ExerciseSubstitutions
    with TableInfo<$ExerciseSubstitutionsTable, ExerciseSubstitution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSubstitutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutDayIdMeta =
      const VerificationMeta('workoutDayId');
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
      'workout_day_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prescribedExerciseCanonicalMeta =
      const VerificationMeta('prescribedExerciseCanonical');
  @override
  late final GeneratedColumn<String> prescribedExerciseCanonical =
      GeneratedColumn<String>(
          'prescribed_exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _substituteExerciseCanonicalMeta =
      const VerificationMeta('substituteExerciseCanonical');
  @override
  late final GeneratedColumn<String> substituteExerciseCanonical =
      GeneratedColumn<String>(
          'substitute_exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonCodeMeta =
      const VerificationMeta('reasonCode');
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
      'reason_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonNotesMeta =
      const VerificationMeta('reasonNotes');
  @override
  late final GeneratedColumn<String> reasonNotes = GeneratedColumn<String>(
      'reason_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _selectedAtMeta =
      const VerificationMeta('selectedAt');
  @override
  late final GeneratedColumn<int> selectedAt = GeneratedColumn<int>(
      'selected_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _selectedByMeta =
      const VerificationMeta('selectedBy');
  @override
  late final GeneratedColumn<String> selectedBy = GeneratedColumn<String>(
      'selected_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _matchScoreMeta =
      const VerificationMeta('matchScore');
  @override
  late final GeneratedColumn<double> matchScore = GeneratedColumn<double>(
      'match_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _matchExplanationJsonMeta =
      const VerificationMeta('matchExplanationJson');
  @override
  late final GeneratedColumn<String> matchExplanationJson =
      GeneratedColumn<String>('match_explanation_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _warningAcknowledgedMeta =
      const VerificationMeta('warningAcknowledged');
  @override
  late final GeneratedColumn<bool> warningAcknowledged = GeneratedColumn<bool>(
      'warning_acknowledged', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("warning_acknowledged" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workoutDayId,
        planDayId,
        prescribedExerciseCanonical,
        substituteExerciseCanonical,
        reasonCode,
        reasonNotes,
        selectedAt,
        selectedBy,
        matchScore,
        matchExplanationJson,
        warningAcknowledged,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_substitutions';
  @override
  VerificationContext validateIntegrity(
      Insertable<ExerciseSubstitution> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
          _workoutDayIdMeta,
          workoutDayId.isAcceptableOrUnknown(
              data['workout_day_id']!, _workoutDayIdMeta));
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    }
    if (data.containsKey('prescribed_exercise_canonical')) {
      context.handle(
          _prescribedExerciseCanonicalMeta,
          prescribedExerciseCanonical.isAcceptableOrUnknown(
              data['prescribed_exercise_canonical']!,
              _prescribedExerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_prescribedExerciseCanonicalMeta);
    }
    if (data.containsKey('substitute_exercise_canonical')) {
      context.handle(
          _substituteExerciseCanonicalMeta,
          substituteExerciseCanonical.isAcceptableOrUnknown(
              data['substitute_exercise_canonical']!,
              _substituteExerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_substituteExerciseCanonicalMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
          _reasonCodeMeta,
          reasonCode.isAcceptableOrUnknown(
              data['reason_code']!, _reasonCodeMeta));
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('reason_notes')) {
      context.handle(
          _reasonNotesMeta,
          reasonNotes.isAcceptableOrUnknown(
              data['reason_notes']!, _reasonNotesMeta));
    }
    if (data.containsKey('selected_at')) {
      context.handle(
          _selectedAtMeta,
          selectedAt.isAcceptableOrUnknown(
              data['selected_at']!, _selectedAtMeta));
    } else if (isInserting) {
      context.missing(_selectedAtMeta);
    }
    if (data.containsKey('selected_by')) {
      context.handle(
          _selectedByMeta,
          selectedBy.isAcceptableOrUnknown(
              data['selected_by']!, _selectedByMeta));
    }
    if (data.containsKey('match_score')) {
      context.handle(
          _matchScoreMeta,
          matchScore.isAcceptableOrUnknown(
              data['match_score']!, _matchScoreMeta));
    }
    if (data.containsKey('match_explanation_json')) {
      context.handle(
          _matchExplanationJsonMeta,
          matchExplanationJson.isAcceptableOrUnknown(
              data['match_explanation_json']!, _matchExplanationJsonMeta));
    }
    if (data.containsKey('warning_acknowledged')) {
      context.handle(
          _warningAcknowledgedMeta,
          warningAcknowledged.isAcceptableOrUnknown(
              data['warning_acknowledged']!, _warningAcknowledgedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseSubstitution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSubstitution(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workoutDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_day_id'])!,
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id']),
      prescribedExerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}prescribed_exercise_canonical'])!,
      substituteExerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}substitute_exercise_canonical'])!,
      reasonCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_code'])!,
      reasonNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_notes']),
      selectedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}selected_at'])!,
      selectedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selected_by']),
      matchScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}match_score']),
      matchExplanationJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}match_explanation_json']),
      warningAcknowledged: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}warning_acknowledged'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExerciseSubstitutionsTable createAlias(String alias) {
    return $ExerciseSubstitutionsTable(attachedDatabase, alias);
  }
}

class ExerciseSubstitution extends DataClass
    implements Insertable<ExerciseSubstitution> {
  final String id;
  final String workoutDayId;
  final String? planDayId;
  final String prescribedExerciseCanonical;
  final String substituteExerciseCanonical;
  final String reasonCode;
  final String? reasonNotes;
  final int selectedAt;
  final String? selectedBy;
  final double? matchScore;
  final String? matchExplanationJson;
  final bool warningAcknowledged;
  final int createdAt;
  const ExerciseSubstitution(
      {required this.id,
      required this.workoutDayId,
      this.planDayId,
      required this.prescribedExerciseCanonical,
      required this.substituteExerciseCanonical,
      required this.reasonCode,
      this.reasonNotes,
      required this.selectedAt,
      this.selectedBy,
      this.matchScore,
      this.matchExplanationJson,
      required this.warningAcknowledged,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<String>(planDayId);
    }
    map['prescribed_exercise_canonical'] =
        Variable<String>(prescribedExerciseCanonical);
    map['substitute_exercise_canonical'] =
        Variable<String>(substituteExerciseCanonical);
    map['reason_code'] = Variable<String>(reasonCode);
    if (!nullToAbsent || reasonNotes != null) {
      map['reason_notes'] = Variable<String>(reasonNotes);
    }
    map['selected_at'] = Variable<int>(selectedAt);
    if (!nullToAbsent || selectedBy != null) {
      map['selected_by'] = Variable<String>(selectedBy);
    }
    if (!nullToAbsent || matchScore != null) {
      map['match_score'] = Variable<double>(matchScore);
    }
    if (!nullToAbsent || matchExplanationJson != null) {
      map['match_explanation_json'] = Variable<String>(matchExplanationJson);
    }
    map['warning_acknowledged'] = Variable<bool>(warningAcknowledged);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ExerciseSubstitutionsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSubstitutionsCompanion(
      id: Value(id),
      workoutDayId: Value(workoutDayId),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      prescribedExerciseCanonical: Value(prescribedExerciseCanonical),
      substituteExerciseCanonical: Value(substituteExerciseCanonical),
      reasonCode: Value(reasonCode),
      reasonNotes: reasonNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonNotes),
      selectedAt: Value(selectedAt),
      selectedBy: selectedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedBy),
      matchScore: matchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(matchScore),
      matchExplanationJson: matchExplanationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(matchExplanationJson),
      warningAcknowledged: Value(warningAcknowledged),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseSubstitution.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSubstitution(
      id: serializer.fromJson<String>(json['id']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      planDayId: serializer.fromJson<String?>(json['planDayId']),
      prescribedExerciseCanonical:
          serializer.fromJson<String>(json['prescribedExerciseCanonical']),
      substituteExerciseCanonical:
          serializer.fromJson<String>(json['substituteExerciseCanonical']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      reasonNotes: serializer.fromJson<String?>(json['reasonNotes']),
      selectedAt: serializer.fromJson<int>(json['selectedAt']),
      selectedBy: serializer.fromJson<String?>(json['selectedBy']),
      matchScore: serializer.fromJson<double?>(json['matchScore']),
      matchExplanationJson:
          serializer.fromJson<String?>(json['matchExplanationJson']),
      warningAcknowledged:
          serializer.fromJson<bool>(json['warningAcknowledged']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'planDayId': serializer.toJson<String?>(planDayId),
      'prescribedExerciseCanonical':
          serializer.toJson<String>(prescribedExerciseCanonical),
      'substituteExerciseCanonical':
          serializer.toJson<String>(substituteExerciseCanonical),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'reasonNotes': serializer.toJson<String?>(reasonNotes),
      'selectedAt': serializer.toJson<int>(selectedAt),
      'selectedBy': serializer.toJson<String?>(selectedBy),
      'matchScore': serializer.toJson<double?>(matchScore),
      'matchExplanationJson': serializer.toJson<String?>(matchExplanationJson),
      'warningAcknowledged': serializer.toJson<bool>(warningAcknowledged),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ExerciseSubstitution copyWith(
          {String? id,
          String? workoutDayId,
          Value<String?> planDayId = const Value.absent(),
          String? prescribedExerciseCanonical,
          String? substituteExerciseCanonical,
          String? reasonCode,
          Value<String?> reasonNotes = const Value.absent(),
          int? selectedAt,
          Value<String?> selectedBy = const Value.absent(),
          Value<double?> matchScore = const Value.absent(),
          Value<String?> matchExplanationJson = const Value.absent(),
          bool? warningAcknowledged,
          int? createdAt}) =>
      ExerciseSubstitution(
        id: id ?? this.id,
        workoutDayId: workoutDayId ?? this.workoutDayId,
        planDayId: planDayId.present ? planDayId.value : this.planDayId,
        prescribedExerciseCanonical:
            prescribedExerciseCanonical ?? this.prescribedExerciseCanonical,
        substituteExerciseCanonical:
            substituteExerciseCanonical ?? this.substituteExerciseCanonical,
        reasonCode: reasonCode ?? this.reasonCode,
        reasonNotes: reasonNotes.present ? reasonNotes.value : this.reasonNotes,
        selectedAt: selectedAt ?? this.selectedAt,
        selectedBy: selectedBy.present ? selectedBy.value : this.selectedBy,
        matchScore: matchScore.present ? matchScore.value : this.matchScore,
        matchExplanationJson: matchExplanationJson.present
            ? matchExplanationJson.value
            : this.matchExplanationJson,
        warningAcknowledged: warningAcknowledged ?? this.warningAcknowledged,
        createdAt: createdAt ?? this.createdAt,
      );
  ExerciseSubstitution copyWithCompanion(ExerciseSubstitutionsCompanion data) {
    return ExerciseSubstitution(
      id: data.id.present ? data.id.value : this.id,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      prescribedExerciseCanonical: data.prescribedExerciseCanonical.present
          ? data.prescribedExerciseCanonical.value
          : this.prescribedExerciseCanonical,
      substituteExerciseCanonical: data.substituteExerciseCanonical.present
          ? data.substituteExerciseCanonical.value
          : this.substituteExerciseCanonical,
      reasonCode:
          data.reasonCode.present ? data.reasonCode.value : this.reasonCode,
      reasonNotes:
          data.reasonNotes.present ? data.reasonNotes.value : this.reasonNotes,
      selectedAt:
          data.selectedAt.present ? data.selectedAt.value : this.selectedAt,
      selectedBy:
          data.selectedBy.present ? data.selectedBy.value : this.selectedBy,
      matchScore:
          data.matchScore.present ? data.matchScore.value : this.matchScore,
      matchExplanationJson: data.matchExplanationJson.present
          ? data.matchExplanationJson.value
          : this.matchExplanationJson,
      warningAcknowledged: data.warningAcknowledged.present
          ? data.warningAcknowledged.value
          : this.warningAcknowledged,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSubstitution(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write('substituteExerciseCanonical: $substituteExerciseCanonical, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonNotes: $reasonNotes, ')
          ..write('selectedAt: $selectedAt, ')
          ..write('selectedBy: $selectedBy, ')
          ..write('matchScore: $matchScore, ')
          ..write('matchExplanationJson: $matchExplanationJson, ')
          ..write('warningAcknowledged: $warningAcknowledged, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      workoutDayId,
      planDayId,
      prescribedExerciseCanonical,
      substituteExerciseCanonical,
      reasonCode,
      reasonNotes,
      selectedAt,
      selectedBy,
      matchScore,
      matchExplanationJson,
      warningAcknowledged,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSubstitution &&
          other.id == this.id &&
          other.workoutDayId == this.workoutDayId &&
          other.planDayId == this.planDayId &&
          other.prescribedExerciseCanonical ==
              this.prescribedExerciseCanonical &&
          other.substituteExerciseCanonical ==
              this.substituteExerciseCanonical &&
          other.reasonCode == this.reasonCode &&
          other.reasonNotes == this.reasonNotes &&
          other.selectedAt == this.selectedAt &&
          other.selectedBy == this.selectedBy &&
          other.matchScore == this.matchScore &&
          other.matchExplanationJson == this.matchExplanationJson &&
          other.warningAcknowledged == this.warningAcknowledged &&
          other.createdAt == this.createdAt);
}

class ExerciseSubstitutionsCompanion
    extends UpdateCompanion<ExerciseSubstitution> {
  final Value<String> id;
  final Value<String> workoutDayId;
  final Value<String?> planDayId;
  final Value<String> prescribedExerciseCanonical;
  final Value<String> substituteExerciseCanonical;
  final Value<String> reasonCode;
  final Value<String?> reasonNotes;
  final Value<int> selectedAt;
  final Value<String?> selectedBy;
  final Value<double?> matchScore;
  final Value<String?> matchExplanationJson;
  final Value<bool> warningAcknowledged;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ExerciseSubstitutionsCompanion({
    this.id = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.prescribedExerciseCanonical = const Value.absent(),
    this.substituteExerciseCanonical = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.reasonNotes = const Value.absent(),
    this.selectedAt = const Value.absent(),
    this.selectedBy = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.matchExplanationJson = const Value.absent(),
    this.warningAcknowledged = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseSubstitutionsCompanion.insert({
    required String id,
    required String workoutDayId,
    this.planDayId = const Value.absent(),
    required String prescribedExerciseCanonical,
    required String substituteExerciseCanonical,
    required String reasonCode,
    this.reasonNotes = const Value.absent(),
    required int selectedAt,
    this.selectedBy = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.matchExplanationJson = const Value.absent(),
    this.warningAcknowledged = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workoutDayId = Value(workoutDayId),
        prescribedExerciseCanonical = Value(prescribedExerciseCanonical),
        substituteExerciseCanonical = Value(substituteExerciseCanonical),
        reasonCode = Value(reasonCode),
        selectedAt = Value(selectedAt),
        createdAt = Value(createdAt);
  static Insertable<ExerciseSubstitution> custom({
    Expression<String>? id,
    Expression<String>? workoutDayId,
    Expression<String>? planDayId,
    Expression<String>? prescribedExerciseCanonical,
    Expression<String>? substituteExerciseCanonical,
    Expression<String>? reasonCode,
    Expression<String>? reasonNotes,
    Expression<int>? selectedAt,
    Expression<String>? selectedBy,
    Expression<double>? matchScore,
    Expression<String>? matchExplanationJson,
    Expression<bool>? warningAcknowledged,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (prescribedExerciseCanonical != null)
        'prescribed_exercise_canonical': prescribedExerciseCanonical,
      if (substituteExerciseCanonical != null)
        'substitute_exercise_canonical': substituteExerciseCanonical,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonNotes != null) 'reason_notes': reasonNotes,
      if (selectedAt != null) 'selected_at': selectedAt,
      if (selectedBy != null) 'selected_by': selectedBy,
      if (matchScore != null) 'match_score': matchScore,
      if (matchExplanationJson != null)
        'match_explanation_json': matchExplanationJson,
      if (warningAcknowledged != null)
        'warning_acknowledged': warningAcknowledged,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseSubstitutionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workoutDayId,
      Value<String?>? planDayId,
      Value<String>? prescribedExerciseCanonical,
      Value<String>? substituteExerciseCanonical,
      Value<String>? reasonCode,
      Value<String?>? reasonNotes,
      Value<int>? selectedAt,
      Value<String?>? selectedBy,
      Value<double?>? matchScore,
      Value<String?>? matchExplanationJson,
      Value<bool>? warningAcknowledged,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ExerciseSubstitutionsCompanion(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      planDayId: planDayId ?? this.planDayId,
      prescribedExerciseCanonical:
          prescribedExerciseCanonical ?? this.prescribedExerciseCanonical,
      substituteExerciseCanonical:
          substituteExerciseCanonical ?? this.substituteExerciseCanonical,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonNotes: reasonNotes ?? this.reasonNotes,
      selectedAt: selectedAt ?? this.selectedAt,
      selectedBy: selectedBy ?? this.selectedBy,
      matchScore: matchScore ?? this.matchScore,
      matchExplanationJson: matchExplanationJson ?? this.matchExplanationJson,
      warningAcknowledged: warningAcknowledged ?? this.warningAcknowledged,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (prescribedExerciseCanonical.present) {
      map['prescribed_exercise_canonical'] =
          Variable<String>(prescribedExerciseCanonical.value);
    }
    if (substituteExerciseCanonical.present) {
      map['substitute_exercise_canonical'] =
          Variable<String>(substituteExerciseCanonical.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (reasonNotes.present) {
      map['reason_notes'] = Variable<String>(reasonNotes.value);
    }
    if (selectedAt.present) {
      map['selected_at'] = Variable<int>(selectedAt.value);
    }
    if (selectedBy.present) {
      map['selected_by'] = Variable<String>(selectedBy.value);
    }
    if (matchScore.present) {
      map['match_score'] = Variable<double>(matchScore.value);
    }
    if (matchExplanationJson.present) {
      map['match_explanation_json'] =
          Variable<String>(matchExplanationJson.value);
    }
    if (warningAcknowledged.present) {
      map['warning_acknowledged'] = Variable<bool>(warningAcknowledged.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSubstitutionsCompanion(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('planDayId: $planDayId, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write('substituteExerciseCanonical: $substituteExerciseCanonical, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonNotes: $reasonNotes, ')
          ..write('selectedAt: $selectedAt, ')
          ..write('selectedBy: $selectedBy, ')
          ..write('matchScore: $matchScore, ')
          ..write('matchExplanationJson: $matchExplanationJson, ')
          ..write('warningAcknowledged: $warningAcknowledged, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanCyclesTable extends PlanCycles
    with TableInfo<$PlanCyclesTable, PlanCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cycleKeyMeta =
      const VerificationMeta('cycleKey');
  @override
  late final GeneratedColumn<String> cycleKey = GeneratedColumn<String>(
      'cycle_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
      'week_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekEndMeta =
      const VerificationMeta('weekEnd');
  @override
  late final GeneratedColumn<String> weekEnd = GeneratedColumn<String>(
      'week_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, cycleKey, weekStart, weekEnd, source, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_cycles';
  @override
  VerificationContext validateIntegrity(Insertable<PlanCycle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_key')) {
      context.handle(_cycleKeyMeta,
          cycleKey.isAcceptableOrUnknown(data['cycle_key']!, _cycleKeyMeta));
    } else if (isInserting) {
      context.missing(_cycleKeyMeta);
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('week_end')) {
      context.handle(_weekEndMeta,
          weekEnd.isAcceptableOrUnknown(data['week_end']!, _weekEndMeta));
    } else if (isInserting) {
      context.missing(_weekEndMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanCycle(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cycleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle_key'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_start'])!,
      weekEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_end'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanCyclesTable createAlias(String alias) {
    return $PlanCyclesTable(attachedDatabase, alias);
  }
}

class PlanCycle extends DataClass implements Insertable<PlanCycle> {
  final String id;
  final String cycleKey;
  final String weekStart;
  final String weekEnd;
  final String source;
  final int createdAt;
  const PlanCycle(
      {required this.id,
      required this.cycleKey,
      required this.weekStart,
      required this.weekEnd,
      required this.source,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_key'] = Variable<String>(cycleKey);
    map['week_start'] = Variable<String>(weekStart);
    map['week_end'] = Variable<String>(weekEnd);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanCyclesCompanion toCompanion(bool nullToAbsent) {
    return PlanCyclesCompanion(
      id: Value(id),
      cycleKey: Value(cycleKey),
      weekStart: Value(weekStart),
      weekEnd: Value(weekEnd),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory PlanCycle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanCycle(
      id: serializer.fromJson<String>(json['id']),
      cycleKey: serializer.fromJson<String>(json['cycleKey']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      weekEnd: serializer.fromJson<String>(json['weekEnd']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleKey': serializer.toJson<String>(cycleKey),
      'weekStart': serializer.toJson<String>(weekStart),
      'weekEnd': serializer.toJson<String>(weekEnd),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanCycle copyWith(
          {String? id,
          String? cycleKey,
          String? weekStart,
          String? weekEnd,
          String? source,
          int? createdAt}) =>
      PlanCycle(
        id: id ?? this.id,
        cycleKey: cycleKey ?? this.cycleKey,
        weekStart: weekStart ?? this.weekStart,
        weekEnd: weekEnd ?? this.weekEnd,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanCycle copyWithCompanion(PlanCyclesCompanion data) {
    return PlanCycle(
      id: data.id.present ? data.id.value : this.id,
      cycleKey: data.cycleKey.present ? data.cycleKey.value : this.cycleKey,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weekEnd: data.weekEnd.present ? data.weekEnd.value : this.weekEnd,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanCycle(')
          ..write('id: $id, ')
          ..write('cycleKey: $cycleKey, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cycleKey, weekStart, weekEnd, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanCycle &&
          other.id == this.id &&
          other.cycleKey == this.cycleKey &&
          other.weekStart == this.weekStart &&
          other.weekEnd == this.weekEnd &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class PlanCyclesCompanion extends UpdateCompanion<PlanCycle> {
  final Value<String> id;
  final Value<String> cycleKey;
  final Value<String> weekStart;
  final Value<String> weekEnd;
  final Value<String> source;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanCyclesCompanion({
    this.id = const Value.absent(),
    this.cycleKey = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.weekEnd = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanCyclesCompanion.insert({
    required String id,
    required String cycleKey,
    required String weekStart,
    required String weekEnd,
    required String source,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        cycleKey = Value(cycleKey),
        weekStart = Value(weekStart),
        weekEnd = Value(weekEnd),
        source = Value(source),
        createdAt = Value(createdAt);
  static Insertable<PlanCycle> custom({
    Expression<String>? id,
    Expression<String>? cycleKey,
    Expression<String>? weekStart,
    Expression<String>? weekEnd,
    Expression<String>? source,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleKey != null) 'cycle_key': cycleKey,
      if (weekStart != null) 'week_start': weekStart,
      if (weekEnd != null) 'week_end': weekEnd,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanCyclesCompanion copyWith(
      {Value<String>? id,
      Value<String>? cycleKey,
      Value<String>? weekStart,
      Value<String>? weekEnd,
      Value<String>? source,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanCyclesCompanion(
      id: id ?? this.id,
      cycleKey: cycleKey ?? this.cycleKey,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleKey.present) {
      map['cycle_key'] = Variable<String>(cycleKey.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (weekEnd.present) {
      map['week_end'] = Variable<String>(weekEnd.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanCyclesCompanion(')
          ..write('id: $id, ')
          ..write('cycleKey: $cycleKey, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanDaysTable extends PlanDays with TableInfo<$PlanDaysTable, PlanDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planCycleIdMeta =
      const VerificationMeta('planCycleId');
  @override
  late final GeneratedColumn<String> planCycleId = GeneratedColumn<String>(
      'plan_cycle_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayNumberMeta =
      const VerificationMeta('dayNumber');
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
      'day_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sheetNameMeta =
      const VerificationMeta('sheetName');
  @override
  late final GeneratedColumn<String> sheetName = GeneratedColumn<String>(
      'sheet_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _estimatedDateMeta =
      const VerificationMeta('estimatedDate');
  @override
  late final GeneratedColumn<String> estimatedDate = GeneratedColumn<String>(
      'estimated_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionTypeMeta =
      const VerificationMeta('sessionType');
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
      'session_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planCycleId,
        dayNumber,
        sheetName,
        estimatedDate,
        sessionType,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_days';
  @override
  VerificationContext validateIntegrity(Insertable<PlanDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_cycle_id')) {
      context.handle(
          _planCycleIdMeta,
          planCycleId.isAcceptableOrUnknown(
              data['plan_cycle_id']!, _planCycleIdMeta));
    } else if (isInserting) {
      context.missing(_planCycleIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(_dayNumberMeta,
          dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta));
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('sheet_name')) {
      context.handle(_sheetNameMeta,
          sheetName.isAcceptableOrUnknown(data['sheet_name']!, _sheetNameMeta));
    } else if (isInserting) {
      context.missing(_sheetNameMeta);
    }
    if (data.containsKey('estimated_date')) {
      context.handle(
          _estimatedDateMeta,
          estimatedDate.isAcceptableOrUnknown(
              data['estimated_date']!, _estimatedDateMeta));
    }
    if (data.containsKey('session_type')) {
      context.handle(
          _sessionTypeMeta,
          sessionType.isAcceptableOrUnknown(
              data['session_type']!, _sessionTypeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planCycleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_cycle_id'])!,
      dayNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_number'])!,
      sheetName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sheet_name'])!,
      estimatedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}estimated_date']),
      sessionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_type']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanDaysTable createAlias(String alias) {
    return $PlanDaysTable(attachedDatabase, alias);
  }
}

class PlanDay extends DataClass implements Insertable<PlanDay> {
  final String id;
  final String planCycleId;
  final int dayNumber;
  final String sheetName;
  final String? estimatedDate;
  final String? sessionType;
  final int createdAt;
  const PlanDay(
      {required this.id,
      required this.planCycleId,
      required this.dayNumber,
      required this.sheetName,
      this.estimatedDate,
      this.sessionType,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_cycle_id'] = Variable<String>(planCycleId);
    map['day_number'] = Variable<int>(dayNumber);
    map['sheet_name'] = Variable<String>(sheetName);
    if (!nullToAbsent || estimatedDate != null) {
      map['estimated_date'] = Variable<String>(estimatedDate);
    }
    if (!nullToAbsent || sessionType != null) {
      map['session_type'] = Variable<String>(sessionType);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanDaysCompanion toCompanion(bool nullToAbsent) {
    return PlanDaysCompanion(
      id: Value(id),
      planCycleId: Value(planCycleId),
      dayNumber: Value(dayNumber),
      sheetName: Value(sheetName),
      estimatedDate: estimatedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDate),
      sessionType: sessionType == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionType),
      createdAt: Value(createdAt),
    );
  }

  factory PlanDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanDay(
      id: serializer.fromJson<String>(json['id']),
      planCycleId: serializer.fromJson<String>(json['planCycleId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      sheetName: serializer.fromJson<String>(json['sheetName']),
      estimatedDate: serializer.fromJson<String?>(json['estimatedDate']),
      sessionType: serializer.fromJson<String?>(json['sessionType']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planCycleId': serializer.toJson<String>(planCycleId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'sheetName': serializer.toJson<String>(sheetName),
      'estimatedDate': serializer.toJson<String?>(estimatedDate),
      'sessionType': serializer.toJson<String?>(sessionType),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanDay copyWith(
          {String? id,
          String? planCycleId,
          int? dayNumber,
          String? sheetName,
          Value<String?> estimatedDate = const Value.absent(),
          Value<String?> sessionType = const Value.absent(),
          int? createdAt}) =>
      PlanDay(
        id: id ?? this.id,
        planCycleId: planCycleId ?? this.planCycleId,
        dayNumber: dayNumber ?? this.dayNumber,
        sheetName: sheetName ?? this.sheetName,
        estimatedDate:
            estimatedDate.present ? estimatedDate.value : this.estimatedDate,
        sessionType: sessionType.present ? sessionType.value : this.sessionType,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanDay copyWithCompanion(PlanDaysCompanion data) {
    return PlanDay(
      id: data.id.present ? data.id.value : this.id,
      planCycleId:
          data.planCycleId.present ? data.planCycleId.value : this.planCycleId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      sheetName: data.sheetName.present ? data.sheetName.value : this.sheetName,
      estimatedDate: data.estimatedDate.present
          ? data.estimatedDate.value
          : this.estimatedDate,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanDay(')
          ..write('id: $id, ')
          ..write('planCycleId: $planCycleId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('sheetName: $sheetName, ')
          ..write('estimatedDate: $estimatedDate, ')
          ..write('sessionType: $sessionType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planCycleId, dayNumber, sheetName,
      estimatedDate, sessionType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanDay &&
          other.id == this.id &&
          other.planCycleId == this.planCycleId &&
          other.dayNumber == this.dayNumber &&
          other.sheetName == this.sheetName &&
          other.estimatedDate == this.estimatedDate &&
          other.sessionType == this.sessionType &&
          other.createdAt == this.createdAt);
}

class PlanDaysCompanion extends UpdateCompanion<PlanDay> {
  final Value<String> id;
  final Value<String> planCycleId;
  final Value<int> dayNumber;
  final Value<String> sheetName;
  final Value<String?> estimatedDate;
  final Value<String?> sessionType;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanDaysCompanion({
    this.id = const Value.absent(),
    this.planCycleId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.sheetName = const Value.absent(),
    this.estimatedDate = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanDaysCompanion.insert({
    required String id,
    required String planCycleId,
    required int dayNumber,
    required String sheetName,
    this.estimatedDate = const Value.absent(),
    this.sessionType = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planCycleId = Value(planCycleId),
        dayNumber = Value(dayNumber),
        sheetName = Value(sheetName),
        createdAt = Value(createdAt);
  static Insertable<PlanDay> custom({
    Expression<String>? id,
    Expression<String>? planCycleId,
    Expression<int>? dayNumber,
    Expression<String>? sheetName,
    Expression<String>? estimatedDate,
    Expression<String>? sessionType,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planCycleId != null) 'plan_cycle_id': planCycleId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (sheetName != null) 'sheet_name': sheetName,
      if (estimatedDate != null) 'estimated_date': estimatedDate,
      if (sessionType != null) 'session_type': sessionType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanDaysCompanion copyWith(
      {Value<String>? id,
      Value<String>? planCycleId,
      Value<int>? dayNumber,
      Value<String>? sheetName,
      Value<String?>? estimatedDate,
      Value<String?>? sessionType,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanDaysCompanion(
      id: id ?? this.id,
      planCycleId: planCycleId ?? this.planCycleId,
      dayNumber: dayNumber ?? this.dayNumber,
      sheetName: sheetName ?? this.sheetName,
      estimatedDate: estimatedDate ?? this.estimatedDate,
      sessionType: sessionType ?? this.sessionType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planCycleId.present) {
      map['plan_cycle_id'] = Variable<String>(planCycleId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (sheetName.present) {
      map['sheet_name'] = Variable<String>(sheetName.value);
    }
    if (estimatedDate.present) {
      map['estimated_date'] = Variable<String>(estimatedDate.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('planCycleId: $planCycleId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('sheetName: $sheetName, ')
          ..write('estimatedDate: $estimatedDate, ')
          ..write('sessionType: $sessionType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanExerciseAlternativesTable extends PlanExerciseAlternatives
    with TableInfo<$PlanExerciseAlternativesTable, PlanExerciseAlternative> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanExerciseAlternativesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prescribedExerciseCanonicalMeta =
      const VerificationMeta('prescribedExerciseCanonical');
  @override
  late final GeneratedColumn<String> prescribedExerciseCanonical =
      GeneratedColumn<String>(
          'prescribed_exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _alternativeExerciseCanonicalMeta =
      const VerificationMeta('alternativeExerciseCanonical');
  @override
  late final GeneratedColumn<String> alternativeExerciseCanonical =
      GeneratedColumn<String>(
          'alternative_exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planDayId,
        prescribedExerciseCanonical,
        alternativeExerciseCanonical,
        priority,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_exercise_alternatives';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlanExerciseAlternative> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    }
    if (data.containsKey('prescribed_exercise_canonical')) {
      context.handle(
          _prescribedExerciseCanonicalMeta,
          prescribedExerciseCanonical.isAcceptableOrUnknown(
              data['prescribed_exercise_canonical']!,
              _prescribedExerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_prescribedExerciseCanonicalMeta);
    }
    if (data.containsKey('alternative_exercise_canonical')) {
      context.handle(
          _alternativeExerciseCanonicalMeta,
          alternativeExerciseCanonical.isAcceptableOrUnknown(
              data['alternative_exercise_canonical']!,
              _alternativeExerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_alternativeExerciseCanonicalMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanExerciseAlternative map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanExerciseAlternative(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id']),
      prescribedExerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}prescribed_exercise_canonical'])!,
      alternativeExerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}alternative_exercise_canonical'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanExerciseAlternativesTable createAlias(String alias) {
    return $PlanExerciseAlternativesTable(attachedDatabase, alias);
  }
}

class PlanExerciseAlternative extends DataClass
    implements Insertable<PlanExerciseAlternative> {
  final String id;
  final String? planDayId;
  final String prescribedExerciseCanonical;
  final String alternativeExerciseCanonical;
  final int priority;
  final String? notes;
  final int createdAt;
  const PlanExerciseAlternative(
      {required this.id,
      this.planDayId,
      required this.prescribedExerciseCanonical,
      required this.alternativeExerciseCanonical,
      required this.priority,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || planDayId != null) {
      map['plan_day_id'] = Variable<String>(planDayId);
    }
    map['prescribed_exercise_canonical'] =
        Variable<String>(prescribedExerciseCanonical);
    map['alternative_exercise_canonical'] =
        Variable<String>(alternativeExerciseCanonical);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanExerciseAlternativesCompanion toCompanion(bool nullToAbsent) {
    return PlanExerciseAlternativesCompanion(
      id: Value(id),
      planDayId: planDayId == null && nullToAbsent
          ? const Value.absent()
          : Value(planDayId),
      prescribedExerciseCanonical: Value(prescribedExerciseCanonical),
      alternativeExerciseCanonical: Value(alternativeExerciseCanonical),
      priority: Value(priority),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PlanExerciseAlternative.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanExerciseAlternative(
      id: serializer.fromJson<String>(json['id']),
      planDayId: serializer.fromJson<String?>(json['planDayId']),
      prescribedExerciseCanonical:
          serializer.fromJson<String>(json['prescribedExerciseCanonical']),
      alternativeExerciseCanonical:
          serializer.fromJson<String>(json['alternativeExerciseCanonical']),
      priority: serializer.fromJson<int>(json['priority']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planDayId': serializer.toJson<String?>(planDayId),
      'prescribedExerciseCanonical':
          serializer.toJson<String>(prescribedExerciseCanonical),
      'alternativeExerciseCanonical':
          serializer.toJson<String>(alternativeExerciseCanonical),
      'priority': serializer.toJson<int>(priority),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanExerciseAlternative copyWith(
          {String? id,
          Value<String?> planDayId = const Value.absent(),
          String? prescribedExerciseCanonical,
          String? alternativeExerciseCanonical,
          int? priority,
          Value<String?> notes = const Value.absent(),
          int? createdAt}) =>
      PlanExerciseAlternative(
        id: id ?? this.id,
        planDayId: planDayId.present ? planDayId.value : this.planDayId,
        prescribedExerciseCanonical:
            prescribedExerciseCanonical ?? this.prescribedExerciseCanonical,
        alternativeExerciseCanonical:
            alternativeExerciseCanonical ?? this.alternativeExerciseCanonical,
        priority: priority ?? this.priority,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanExerciseAlternative copyWithCompanion(
      PlanExerciseAlternativesCompanion data) {
    return PlanExerciseAlternative(
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      prescribedExerciseCanonical: data.prescribedExerciseCanonical.present
          ? data.prescribedExerciseCanonical.value
          : this.prescribedExerciseCanonical,
      alternativeExerciseCanonical: data.alternativeExerciseCanonical.present
          ? data.alternativeExerciseCanonical.value
          : this.alternativeExerciseCanonical,
      priority: data.priority.present ? data.priority.value : this.priority,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanExerciseAlternative(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write(
              'alternativeExerciseCanonical: $alternativeExerciseCanonical, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planDayId, prescribedExerciseCanonical,
      alternativeExerciseCanonical, priority, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanExerciseAlternative &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.prescribedExerciseCanonical ==
              this.prescribedExerciseCanonical &&
          other.alternativeExerciseCanonical ==
              this.alternativeExerciseCanonical &&
          other.priority == this.priority &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PlanExerciseAlternativesCompanion
    extends UpdateCompanion<PlanExerciseAlternative> {
  final Value<String> id;
  final Value<String?> planDayId;
  final Value<String> prescribedExerciseCanonical;
  final Value<String> alternativeExerciseCanonical;
  final Value<int> priority;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanExerciseAlternativesCompanion({
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.prescribedExerciseCanonical = const Value.absent(),
    this.alternativeExerciseCanonical = const Value.absent(),
    this.priority = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanExerciseAlternativesCompanion.insert({
    required String id,
    this.planDayId = const Value.absent(),
    required String prescribedExerciseCanonical,
    required String alternativeExerciseCanonical,
    this.priority = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        prescribedExerciseCanonical = Value(prescribedExerciseCanonical),
        alternativeExerciseCanonical = Value(alternativeExerciseCanonical),
        createdAt = Value(createdAt);
  static Insertable<PlanExerciseAlternative> custom({
    Expression<String>? id,
    Expression<String>? planDayId,
    Expression<String>? prescribedExerciseCanonical,
    Expression<String>? alternativeExerciseCanonical,
    Expression<int>? priority,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (prescribedExerciseCanonical != null)
        'prescribed_exercise_canonical': prescribedExerciseCanonical,
      if (alternativeExerciseCanonical != null)
        'alternative_exercise_canonical': alternativeExerciseCanonical,
      if (priority != null) 'priority': priority,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanExerciseAlternativesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? planDayId,
      Value<String>? prescribedExerciseCanonical,
      Value<String>? alternativeExerciseCanonical,
      Value<int>? priority,
      Value<String?>? notes,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanExerciseAlternativesCompanion(
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      prescribedExerciseCanonical:
          prescribedExerciseCanonical ?? this.prescribedExerciseCanonical,
      alternativeExerciseCanonical:
          alternativeExerciseCanonical ?? this.alternativeExerciseCanonical,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (prescribedExerciseCanonical.present) {
      map['prescribed_exercise_canonical'] =
          Variable<String>(prescribedExerciseCanonical.value);
    }
    if (alternativeExerciseCanonical.present) {
      map['alternative_exercise_canonical'] =
          Variable<String>(alternativeExerciseCanonical.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanExerciseAlternativesCompanion(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('prescribedExerciseCanonical: $prescribedExerciseCanonical, ')
          ..write(
              'alternativeExerciseCanonical: $alternativeExerciseCanonical, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanPrescribedStrengthSetsTable extends PlanPrescribedStrengthSets
    with
        TableInfo<$PlanPrescribedStrengthSetsTable, PlanPrescribedStrengthSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanPrescribedStrengthSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseCanonicalMeta =
      const VerificationMeta('exerciseCanonical');
  @override
  late final GeneratedColumn<String> exerciseCanonical =
      GeneratedColumn<String>('exercise_canonical', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIndexMeta =
      const VerificationMeta('setIndex');
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
      'set_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
      'rir', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawSetStringMeta =
      const VerificationMeta('rawSetString');
  @override
  late final GeneratedColumn<String> rawSetString = GeneratedColumn<String>(
      'raw_set_string', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planDayId,
        exerciseCanonical,
        setIndex,
        weight,
        reps,
        rir,
        unit,
        rawSetString,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_prescribed_strength_sets';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlanPrescribedStrengthSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    } else if (isInserting) {
      context.missing(_planDayIdMeta);
    }
    if (data.containsKey('exercise_canonical')) {
      context.handle(
          _exerciseCanonicalMeta,
          exerciseCanonical.isAcceptableOrUnknown(
              data['exercise_canonical']!, _exerciseCanonicalMeta));
    } else if (isInserting) {
      context.missing(_exerciseCanonicalMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(_setIndexMeta,
          setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta));
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('rir')) {
      context.handle(
          _rirMeta, rir.isAcceptableOrUnknown(data['rir']!, _rirMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('raw_set_string')) {
      context.handle(
          _rawSetStringMeta,
          rawSetString.isAcceptableOrUnknown(
              data['raw_set_string']!, _rawSetStringMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanPrescribedStrengthSet map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanPrescribedStrengthSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id'])!,
      exerciseCanonical: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exercise_canonical'])!,
      setIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_index'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps']),
      rir: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rir']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      rawSetString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_set_string']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanPrescribedStrengthSetsTable createAlias(String alias) {
    return $PlanPrescribedStrengthSetsTable(attachedDatabase, alias);
  }
}

class PlanPrescribedStrengthSet extends DataClass
    implements Insertable<PlanPrescribedStrengthSet> {
  final String id;
  final String planDayId;
  final String exerciseCanonical;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
  final String? rawSetString;
  final int createdAt;
  const PlanPrescribedStrengthSet(
      {required this.id,
      required this.planDayId,
      required this.exerciseCanonical,
      required this.setIndex,
      this.weight,
      this.reps,
      this.rir,
      required this.unit,
      this.rawSetString,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_day_id'] = Variable<String>(planDayId);
    map['exercise_canonical'] = Variable<String>(exerciseCanonical);
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || rawSetString != null) {
      map['raw_set_string'] = Variable<String>(rawSetString);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanPrescribedStrengthSetsCompanion toCompanion(bool nullToAbsent) {
    return PlanPrescribedStrengthSetsCompanion(
      id: Value(id),
      planDayId: Value(planDayId),
      exerciseCanonical: Value(exerciseCanonical),
      setIndex: Value(setIndex),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      unit: Value(unit),
      rawSetString: rawSetString == null && nullToAbsent
          ? const Value.absent()
          : Value(rawSetString),
      createdAt: Value(createdAt),
    );
  }

  factory PlanPrescribedStrengthSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanPrescribedStrengthSet(
      id: serializer.fromJson<String>(json['id']),
      planDayId: serializer.fromJson<String>(json['planDayId']),
      exerciseCanonical: serializer.fromJson<String>(json['exerciseCanonical']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weight: serializer.fromJson<double?>(json['weight']),
      reps: serializer.fromJson<int?>(json['reps']),
      rir: serializer.fromJson<int?>(json['rir']),
      unit: serializer.fromJson<String>(json['unit']),
      rawSetString: serializer.fromJson<String?>(json['rawSetString']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planDayId': serializer.toJson<String>(planDayId),
      'exerciseCanonical': serializer.toJson<String>(exerciseCanonical),
      'setIndex': serializer.toJson<int>(setIndex),
      'weight': serializer.toJson<double?>(weight),
      'reps': serializer.toJson<int?>(reps),
      'rir': serializer.toJson<int?>(rir),
      'unit': serializer.toJson<String>(unit),
      'rawSetString': serializer.toJson<String?>(rawSetString),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanPrescribedStrengthSet copyWith(
          {String? id,
          String? planDayId,
          String? exerciseCanonical,
          int? setIndex,
          Value<double?> weight = const Value.absent(),
          Value<int?> reps = const Value.absent(),
          Value<int?> rir = const Value.absent(),
          String? unit,
          Value<String?> rawSetString = const Value.absent(),
          int? createdAt}) =>
      PlanPrescribedStrengthSet(
        id: id ?? this.id,
        planDayId: planDayId ?? this.planDayId,
        exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
        setIndex: setIndex ?? this.setIndex,
        weight: weight.present ? weight.value : this.weight,
        reps: reps.present ? reps.value : this.reps,
        rir: rir.present ? rir.value : this.rir,
        unit: unit ?? this.unit,
        rawSetString:
            rawSetString.present ? rawSetString.value : this.rawSetString,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanPrescribedStrengthSet copyWithCompanion(
      PlanPrescribedStrengthSetsCompanion data) {
    return PlanPrescribedStrengthSet(
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      exerciseCanonical: data.exerciseCanonical.present
          ? data.exerciseCanonical.value
          : this.exerciseCanonical,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      rir: data.rir.present ? data.rir.value : this.rir,
      unit: data.unit.present ? data.unit.value : this.unit,
      rawSetString: data.rawSetString.present
          ? data.rawSetString.value
          : this.rawSetString,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanPrescribedStrengthSet(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit, ')
          ..write('rawSetString: $rawSetString, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planDayId, exerciseCanonical, setIndex,
      weight, reps, rir, unit, rawSetString, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanPrescribedStrengthSet &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.exerciseCanonical == this.exerciseCanonical &&
          other.setIndex == this.setIndex &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.rir == this.rir &&
          other.unit == this.unit &&
          other.rawSetString == this.rawSetString &&
          other.createdAt == this.createdAt);
}

class PlanPrescribedStrengthSetsCompanion
    extends UpdateCompanion<PlanPrescribedStrengthSet> {
  final Value<String> id;
  final Value<String> planDayId;
  final Value<String> exerciseCanonical;
  final Value<int> setIndex;
  final Value<double?> weight;
  final Value<int?> reps;
  final Value<int?> rir;
  final Value<String> unit;
  final Value<String?> rawSetString;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanPrescribedStrengthSetsCompanion({
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.exerciseCanonical = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    this.unit = const Value.absent(),
    this.rawSetString = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanPrescribedStrengthSetsCompanion.insert({
    required String id,
    required String planDayId,
    required String exerciseCanonical,
    required int setIndex,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.rir = const Value.absent(),
    required String unit,
    this.rawSetString = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planDayId = Value(planDayId),
        exerciseCanonical = Value(exerciseCanonical),
        setIndex = Value(setIndex),
        unit = Value(unit),
        createdAt = Value(createdAt);
  static Insertable<PlanPrescribedStrengthSet> custom({
    Expression<String>? id,
    Expression<String>? planDayId,
    Expression<String>? exerciseCanonical,
    Expression<int>? setIndex,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? rir,
    Expression<String>? unit,
    Expression<String>? rawSetString,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (exerciseCanonical != null) 'exercise_canonical': exerciseCanonical,
      if (setIndex != null) 'set_index': setIndex,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (rir != null) 'rir': rir,
      if (unit != null) 'unit': unit,
      if (rawSetString != null) 'raw_set_string': rawSetString,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanPrescribedStrengthSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? planDayId,
      Value<String>? exerciseCanonical,
      Value<int>? setIndex,
      Value<double?>? weight,
      Value<int?>? reps,
      Value<int?>? rir,
      Value<String>? unit,
      Value<String?>? rawSetString,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanPrescribedStrengthSetsCompanion(
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      exerciseCanonical: exerciseCanonical ?? this.exerciseCanonical,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      unit: unit ?? this.unit,
      rawSetString: rawSetString ?? this.rawSetString,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (exerciseCanonical.present) {
      map['exercise_canonical'] = Variable<String>(exerciseCanonical.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (rawSetString.present) {
      map['raw_set_string'] = Variable<String>(rawSetString.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanPrescribedStrengthSetsCompanion(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('exerciseCanonical: $exerciseCanonical, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('rir: $rir, ')
          ..write('unit: $unit, ')
          ..write('rawSetString: $rawSetString, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanPrescribedRunsTable extends PlanPrescribedRuns
    with TableInfo<$PlanPrescribedRunsTable, PlanPrescribedRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanPrescribedRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDayIdMeta =
      const VerificationMeta('planDayId');
  @override
  late final GeneratedColumn<String> planDayId = GeneratedColumn<String>(
      'plan_day_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayLabelMeta =
      const VerificationMeta('dayLabel');
  @override
  late final GeneratedColumn<String> dayLabel = GeneratedColumn<String>(
      'day_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _liftFocusMeta =
      const VerificationMeta('liftFocus');
  @override
  late final GeneratedColumn<String> liftFocus = GeneratedColumn<String>(
      'lift_focus', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _runTypeMeta =
      const VerificationMeta('runType');
  @override
  late final GeneratedColumn<String> runType = GeneratedColumn<String>(
      'run_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationTextMeta =
      const VerificationMeta('durationText');
  @override
  late final GeneratedColumn<String> durationText = GeneratedColumn<String>(
      'duration_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetPaceMeta =
      const VerificationMeta('targetPace');
  @override
  late final GeneratedColumn<String> targetPace = GeneratedColumn<String>(
      'target_pace', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effortHrGuardrailsMeta =
      const VerificationMeta('effortHrGuardrails');
  @override
  late final GeneratedColumn<String> effortHrGuardrails =
      GeneratedColumn<String>('effort_hr_guardrails', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planDayId,
        dayLabel,
        liftFocus,
        runType,
        durationText,
        targetPace,
        effortHrGuardrails,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_prescribed_runs';
  @override
  VerificationContext validateIntegrity(Insertable<PlanPrescribedRun> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_day_id')) {
      context.handle(
          _planDayIdMeta,
          planDayId.isAcceptableOrUnknown(
              data['plan_day_id']!, _planDayIdMeta));
    } else if (isInserting) {
      context.missing(_planDayIdMeta);
    }
    if (data.containsKey('day_label')) {
      context.handle(_dayLabelMeta,
          dayLabel.isAcceptableOrUnknown(data['day_label']!, _dayLabelMeta));
    }
    if (data.containsKey('lift_focus')) {
      context.handle(_liftFocusMeta,
          liftFocus.isAcceptableOrUnknown(data['lift_focus']!, _liftFocusMeta));
    }
    if (data.containsKey('run_type')) {
      context.handle(_runTypeMeta,
          runType.isAcceptableOrUnknown(data['run_type']!, _runTypeMeta));
    }
    if (data.containsKey('duration_text')) {
      context.handle(
          _durationTextMeta,
          durationText.isAcceptableOrUnknown(
              data['duration_text']!, _durationTextMeta));
    }
    if (data.containsKey('target_pace')) {
      context.handle(
          _targetPaceMeta,
          targetPace.isAcceptableOrUnknown(
              data['target_pace']!, _targetPaceMeta));
    }
    if (data.containsKey('effort_hr_guardrails')) {
      context.handle(
          _effortHrGuardrailsMeta,
          effortHrGuardrails.isAcceptableOrUnknown(
              data['effort_hr_guardrails']!, _effortHrGuardrailsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanPrescribedRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanPrescribedRun(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planDayId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_day_id'])!,
      dayLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_label']),
      liftFocus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lift_focus']),
      runType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_type']),
      durationText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}duration_text']),
      targetPace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_pace']),
      effortHrGuardrails: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}effort_hr_guardrails']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanPrescribedRunsTable createAlias(String alias) {
    return $PlanPrescribedRunsTable(attachedDatabase, alias);
  }
}

class PlanPrescribedRun extends DataClass
    implements Insertable<PlanPrescribedRun> {
  final String id;
  final String planDayId;
  final String? dayLabel;
  final String? liftFocus;
  final String? runType;
  final String? durationText;
  final String? targetPace;
  final String? effortHrGuardrails;
  final String? notes;
  final int createdAt;
  const PlanPrescribedRun(
      {required this.id,
      required this.planDayId,
      this.dayLabel,
      this.liftFocus,
      this.runType,
      this.durationText,
      this.targetPace,
      this.effortHrGuardrails,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_day_id'] = Variable<String>(planDayId);
    if (!nullToAbsent || dayLabel != null) {
      map['day_label'] = Variable<String>(dayLabel);
    }
    if (!nullToAbsent || liftFocus != null) {
      map['lift_focus'] = Variable<String>(liftFocus);
    }
    if (!nullToAbsent || runType != null) {
      map['run_type'] = Variable<String>(runType);
    }
    if (!nullToAbsent || durationText != null) {
      map['duration_text'] = Variable<String>(durationText);
    }
    if (!nullToAbsent || targetPace != null) {
      map['target_pace'] = Variable<String>(targetPace);
    }
    if (!nullToAbsent || effortHrGuardrails != null) {
      map['effort_hr_guardrails'] = Variable<String>(effortHrGuardrails);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanPrescribedRunsCompanion toCompanion(bool nullToAbsent) {
    return PlanPrescribedRunsCompanion(
      id: Value(id),
      planDayId: Value(planDayId),
      dayLabel: dayLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(dayLabel),
      liftFocus: liftFocus == null && nullToAbsent
          ? const Value.absent()
          : Value(liftFocus),
      runType: runType == null && nullToAbsent
          ? const Value.absent()
          : Value(runType),
      durationText: durationText == null && nullToAbsent
          ? const Value.absent()
          : Value(durationText),
      targetPace: targetPace == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPace),
      effortHrGuardrails: effortHrGuardrails == null && nullToAbsent
          ? const Value.absent()
          : Value(effortHrGuardrails),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PlanPrescribedRun.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanPrescribedRun(
      id: serializer.fromJson<String>(json['id']),
      planDayId: serializer.fromJson<String>(json['planDayId']),
      dayLabel: serializer.fromJson<String?>(json['dayLabel']),
      liftFocus: serializer.fromJson<String?>(json['liftFocus']),
      runType: serializer.fromJson<String?>(json['runType']),
      durationText: serializer.fromJson<String?>(json['durationText']),
      targetPace: serializer.fromJson<String?>(json['targetPace']),
      effortHrGuardrails:
          serializer.fromJson<String?>(json['effortHrGuardrails']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planDayId': serializer.toJson<String>(planDayId),
      'dayLabel': serializer.toJson<String?>(dayLabel),
      'liftFocus': serializer.toJson<String?>(liftFocus),
      'runType': serializer.toJson<String?>(runType),
      'durationText': serializer.toJson<String?>(durationText),
      'targetPace': serializer.toJson<String?>(targetPace),
      'effortHrGuardrails': serializer.toJson<String?>(effortHrGuardrails),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanPrescribedRun copyWith(
          {String? id,
          String? planDayId,
          Value<String?> dayLabel = const Value.absent(),
          Value<String?> liftFocus = const Value.absent(),
          Value<String?> runType = const Value.absent(),
          Value<String?> durationText = const Value.absent(),
          Value<String?> targetPace = const Value.absent(),
          Value<String?> effortHrGuardrails = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          int? createdAt}) =>
      PlanPrescribedRun(
        id: id ?? this.id,
        planDayId: planDayId ?? this.planDayId,
        dayLabel: dayLabel.present ? dayLabel.value : this.dayLabel,
        liftFocus: liftFocus.present ? liftFocus.value : this.liftFocus,
        runType: runType.present ? runType.value : this.runType,
        durationText:
            durationText.present ? durationText.value : this.durationText,
        targetPace: targetPace.present ? targetPace.value : this.targetPace,
        effortHrGuardrails: effortHrGuardrails.present
            ? effortHrGuardrails.value
            : this.effortHrGuardrails,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanPrescribedRun copyWithCompanion(PlanPrescribedRunsCompanion data) {
    return PlanPrescribedRun(
      id: data.id.present ? data.id.value : this.id,
      planDayId: data.planDayId.present ? data.planDayId.value : this.planDayId,
      dayLabel: data.dayLabel.present ? data.dayLabel.value : this.dayLabel,
      liftFocus: data.liftFocus.present ? data.liftFocus.value : this.liftFocus,
      runType: data.runType.present ? data.runType.value : this.runType,
      durationText: data.durationText.present
          ? data.durationText.value
          : this.durationText,
      targetPace:
          data.targetPace.present ? data.targetPace.value : this.targetPace,
      effortHrGuardrails: data.effortHrGuardrails.present
          ? data.effortHrGuardrails.value
          : this.effortHrGuardrails,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanPrescribedRun(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('dayLabel: $dayLabel, ')
          ..write('liftFocus: $liftFocus, ')
          ..write('runType: $runType, ')
          ..write('durationText: $durationText, ')
          ..write('targetPace: $targetPace, ')
          ..write('effortHrGuardrails: $effortHrGuardrails, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planDayId, dayLabel, liftFocus, runType,
      durationText, targetPace, effortHrGuardrails, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanPrescribedRun &&
          other.id == this.id &&
          other.planDayId == this.planDayId &&
          other.dayLabel == this.dayLabel &&
          other.liftFocus == this.liftFocus &&
          other.runType == this.runType &&
          other.durationText == this.durationText &&
          other.targetPace == this.targetPace &&
          other.effortHrGuardrails == this.effortHrGuardrails &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PlanPrescribedRunsCompanion extends UpdateCompanion<PlanPrescribedRun> {
  final Value<String> id;
  final Value<String> planDayId;
  final Value<String?> dayLabel;
  final Value<String?> liftFocus;
  final Value<String?> runType;
  final Value<String?> durationText;
  final Value<String?> targetPace;
  final Value<String?> effortHrGuardrails;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanPrescribedRunsCompanion({
    this.id = const Value.absent(),
    this.planDayId = const Value.absent(),
    this.dayLabel = const Value.absent(),
    this.liftFocus = const Value.absent(),
    this.runType = const Value.absent(),
    this.durationText = const Value.absent(),
    this.targetPace = const Value.absent(),
    this.effortHrGuardrails = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanPrescribedRunsCompanion.insert({
    required String id,
    required String planDayId,
    this.dayLabel = const Value.absent(),
    this.liftFocus = const Value.absent(),
    this.runType = const Value.absent(),
    this.durationText = const Value.absent(),
    this.targetPace = const Value.absent(),
    this.effortHrGuardrails = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planDayId = Value(planDayId),
        createdAt = Value(createdAt);
  static Insertable<PlanPrescribedRun> custom({
    Expression<String>? id,
    Expression<String>? planDayId,
    Expression<String>? dayLabel,
    Expression<String>? liftFocus,
    Expression<String>? runType,
    Expression<String>? durationText,
    Expression<String>? targetPace,
    Expression<String>? effortHrGuardrails,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDayId != null) 'plan_day_id': planDayId,
      if (dayLabel != null) 'day_label': dayLabel,
      if (liftFocus != null) 'lift_focus': liftFocus,
      if (runType != null) 'run_type': runType,
      if (durationText != null) 'duration_text': durationText,
      if (targetPace != null) 'target_pace': targetPace,
      if (effortHrGuardrails != null)
        'effort_hr_guardrails': effortHrGuardrails,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanPrescribedRunsCompanion copyWith(
      {Value<String>? id,
      Value<String>? planDayId,
      Value<String?>? dayLabel,
      Value<String?>? liftFocus,
      Value<String?>? runType,
      Value<String?>? durationText,
      Value<String?>? targetPace,
      Value<String?>? effortHrGuardrails,
      Value<String?>? notes,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanPrescribedRunsCompanion(
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      dayLabel: dayLabel ?? this.dayLabel,
      liftFocus: liftFocus ?? this.liftFocus,
      runType: runType ?? this.runType,
      durationText: durationText ?? this.durationText,
      targetPace: targetPace ?? this.targetPace,
      effortHrGuardrails: effortHrGuardrails ?? this.effortHrGuardrails,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDayId.present) {
      map['plan_day_id'] = Variable<String>(planDayId.value);
    }
    if (dayLabel.present) {
      map['day_label'] = Variable<String>(dayLabel.value);
    }
    if (liftFocus.present) {
      map['lift_focus'] = Variable<String>(liftFocus.value);
    }
    if (runType.present) {
      map['run_type'] = Variable<String>(runType.value);
    }
    if (durationText.present) {
      map['duration_text'] = Variable<String>(durationText.value);
    }
    if (targetPace.present) {
      map['target_pace'] = Variable<String>(targetPace.value);
    }
    if (effortHrGuardrails.present) {
      map['effort_hr_guardrails'] = Variable<String>(effortHrGuardrails.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanPrescribedRunsCompanion(')
          ..write('id: $id, ')
          ..write('planDayId: $planDayId, ')
          ..write('dayLabel: $dayLabel, ')
          ..write('liftFocus: $liftFocus, ')
          ..write('runType: $runType, ')
          ..write('durationText: $durationText, ')
          ..write('targetPace: $targetPace, ')
          ..write('effortHrGuardrails: $effortHrGuardrails, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanLongRangeWeeksTable extends PlanLongRangeWeeks
    with TableInfo<$PlanLongRangeWeeksTable, PlanLongRangeWeek> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanLongRangeWeeksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekLabelMeta =
      const VerificationMeta('weekLabel');
  @override
  late final GeneratedColumn<String> weekLabel = GeneratedColumn<String>(
      'week_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekNumberMeta =
      const VerificationMeta('weekNumber');
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
      'week_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
      'week_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekEndMeta =
      const VerificationMeta('weekEnd');
  @override
  late final GeneratedColumn<String> weekEnd = GeneratedColumn<String>(
      'week_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runFocusMeta =
      const VerificationMeta('runFocus');
  @override
  late final GeneratedColumn<String> runFocus = GeneratedColumn<String>(
      'run_focus', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strengthFocusMeta =
      const VerificationMeta('strengthFocus');
  @override
  late final GeneratedColumn<String> strengthFocus = GeneratedColumn<String>(
      'strength_focus', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strengthProgressionExpectationMeta =
      const VerificationMeta('strengthProgressionExpectation');
  @override
  late final GeneratedColumn<String> strengthProgressionExpectation =
      GeneratedColumn<String>(
          'strength_progression_expectation', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _primaryProgressionTargetMeta =
      const VerificationMeta('primaryProgressionTarget');
  @override
  late final GeneratedColumn<String> primaryProgressionTarget =
      GeneratedColumn<String>('primary_progression_target', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recoveryEmphasisMeta =
      const VerificationMeta('recoveryEmphasis');
  @override
  late final GeneratedColumn<String> recoveryEmphasis = GeneratedColumn<String>(
      'recovery_emphasis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deloadMeta = const VerificationMeta('deload');
  @override
  late final GeneratedColumn<bool> deload = GeneratedColumn<bool>(
      'deload', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deload" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastPlanCycleIdMeta =
      const VerificationMeta('lastPlanCycleId');
  @override
  late final GeneratedColumn<String> lastPlanCycleId = GeneratedColumn<String>(
      'last_plan_cycle_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        weekLabel,
        weekNumber,
        weekStart,
        weekEnd,
        runFocus,
        strengthFocus,
        strengthProgressionExpectation,
        primaryProgressionTarget,
        recoveryEmphasis,
        deload,
        notes,
        source,
        lastPlanCycleId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_long_range_weeks';
  @override
  VerificationContext validateIntegrity(Insertable<PlanLongRangeWeek> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('week_label')) {
      context.handle(_weekLabelMeta,
          weekLabel.isAcceptableOrUnknown(data['week_label']!, _weekLabelMeta));
    } else if (isInserting) {
      context.missing(_weekLabelMeta);
    }
    if (data.containsKey('week_number')) {
      context.handle(
          _weekNumberMeta,
          weekNumber.isAcceptableOrUnknown(
              data['week_number']!, _weekNumberMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('week_end')) {
      context.handle(_weekEndMeta,
          weekEnd.isAcceptableOrUnknown(data['week_end']!, _weekEndMeta));
    } else if (isInserting) {
      context.missing(_weekEndMeta);
    }
    if (data.containsKey('run_focus')) {
      context.handle(_runFocusMeta,
          runFocus.isAcceptableOrUnknown(data['run_focus']!, _runFocusMeta));
    }
    if (data.containsKey('strength_focus')) {
      context.handle(
          _strengthFocusMeta,
          strengthFocus.isAcceptableOrUnknown(
              data['strength_focus']!, _strengthFocusMeta));
    }
    if (data.containsKey('strength_progression_expectation')) {
      context.handle(
          _strengthProgressionExpectationMeta,
          strengthProgressionExpectation.isAcceptableOrUnknown(
              data['strength_progression_expectation']!,
              _strengthProgressionExpectationMeta));
    }
    if (data.containsKey('primary_progression_target')) {
      context.handle(
          _primaryProgressionTargetMeta,
          primaryProgressionTarget.isAcceptableOrUnknown(
              data['primary_progression_target']!,
              _primaryProgressionTargetMeta));
    }
    if (data.containsKey('recovery_emphasis')) {
      context.handle(
          _recoveryEmphasisMeta,
          recoveryEmphasis.isAcceptableOrUnknown(
              data['recovery_emphasis']!, _recoveryEmphasisMeta));
    }
    if (data.containsKey('deload')) {
      context.handle(_deloadMeta,
          deload.isAcceptableOrUnknown(data['deload']!, _deloadMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('last_plan_cycle_id')) {
      context.handle(
          _lastPlanCycleIdMeta,
          lastPlanCycleId.isAcceptableOrUnknown(
              data['last_plan_cycle_id']!, _lastPlanCycleIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanLongRangeWeek map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanLongRangeWeek(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      weekLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_label'])!,
      weekNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}week_number']),
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_start'])!,
      weekEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_end'])!,
      runFocus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_focus']),
      strengthFocus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}strength_focus']),
      strengthProgressionExpectation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strength_progression_expectation']),
      primaryProgressionTarget: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}primary_progression_target']),
      recoveryEmphasis: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recovery_emphasis']),
      deload: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deload'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      lastPlanCycleId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_plan_cycle_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PlanLongRangeWeeksTable createAlias(String alias) {
    return $PlanLongRangeWeeksTable(attachedDatabase, alias);
  }
}

class PlanLongRangeWeek extends DataClass
    implements Insertable<PlanLongRangeWeek> {
  final String id;
  final String weekLabel;
  final int? weekNumber;
  final String weekStart;
  final String weekEnd;
  final String? runFocus;
  final String? strengthFocus;
  final String? strengthProgressionExpectation;
  final String? primaryProgressionTarget;
  final String? recoveryEmphasis;
  final bool deload;
  final String? notes;
  final String source;
  final String? lastPlanCycleId;
  final int createdAt;
  final int updatedAt;
  const PlanLongRangeWeek(
      {required this.id,
      required this.weekLabel,
      this.weekNumber,
      required this.weekStart,
      required this.weekEnd,
      this.runFocus,
      this.strengthFocus,
      this.strengthProgressionExpectation,
      this.primaryProgressionTarget,
      this.recoveryEmphasis,
      required this.deload,
      this.notes,
      required this.source,
      this.lastPlanCycleId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['week_label'] = Variable<String>(weekLabel);
    if (!nullToAbsent || weekNumber != null) {
      map['week_number'] = Variable<int>(weekNumber);
    }
    map['week_start'] = Variable<String>(weekStart);
    map['week_end'] = Variable<String>(weekEnd);
    if (!nullToAbsent || runFocus != null) {
      map['run_focus'] = Variable<String>(runFocus);
    }
    if (!nullToAbsent || strengthFocus != null) {
      map['strength_focus'] = Variable<String>(strengthFocus);
    }
    if (!nullToAbsent || strengthProgressionExpectation != null) {
      map['strength_progression_expectation'] =
          Variable<String>(strengthProgressionExpectation);
    }
    if (!nullToAbsent || primaryProgressionTarget != null) {
      map['primary_progression_target'] =
          Variable<String>(primaryProgressionTarget);
    }
    if (!nullToAbsent || recoveryEmphasis != null) {
      map['recovery_emphasis'] = Variable<String>(recoveryEmphasis);
    }
    map['deload'] = Variable<bool>(deload);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || lastPlanCycleId != null) {
      map['last_plan_cycle_id'] = Variable<String>(lastPlanCycleId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PlanLongRangeWeeksCompanion toCompanion(bool nullToAbsent) {
    return PlanLongRangeWeeksCompanion(
      id: Value(id),
      weekLabel: Value(weekLabel),
      weekNumber: weekNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(weekNumber),
      weekStart: Value(weekStart),
      weekEnd: Value(weekEnd),
      runFocus: runFocus == null && nullToAbsent
          ? const Value.absent()
          : Value(runFocus),
      strengthFocus: strengthFocus == null && nullToAbsent
          ? const Value.absent()
          : Value(strengthFocus),
      strengthProgressionExpectation:
          strengthProgressionExpectation == null && nullToAbsent
              ? const Value.absent()
              : Value(strengthProgressionExpectation),
      primaryProgressionTarget: primaryProgressionTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryProgressionTarget),
      recoveryEmphasis: recoveryEmphasis == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryEmphasis),
      deload: Value(deload),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      source: Value(source),
      lastPlanCycleId: lastPlanCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlanCycleId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlanLongRangeWeek.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanLongRangeWeek(
      id: serializer.fromJson<String>(json['id']),
      weekLabel: serializer.fromJson<String>(json['weekLabel']),
      weekNumber: serializer.fromJson<int?>(json['weekNumber']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      weekEnd: serializer.fromJson<String>(json['weekEnd']),
      runFocus: serializer.fromJson<String?>(json['runFocus']),
      strengthFocus: serializer.fromJson<String?>(json['strengthFocus']),
      strengthProgressionExpectation:
          serializer.fromJson<String?>(json['strengthProgressionExpectation']),
      primaryProgressionTarget:
          serializer.fromJson<String?>(json['primaryProgressionTarget']),
      recoveryEmphasis: serializer.fromJson<String?>(json['recoveryEmphasis']),
      deload: serializer.fromJson<bool>(json['deload']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      lastPlanCycleId: serializer.fromJson<String?>(json['lastPlanCycleId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'weekLabel': serializer.toJson<String>(weekLabel),
      'weekNumber': serializer.toJson<int?>(weekNumber),
      'weekStart': serializer.toJson<String>(weekStart),
      'weekEnd': serializer.toJson<String>(weekEnd),
      'runFocus': serializer.toJson<String?>(runFocus),
      'strengthFocus': serializer.toJson<String?>(strengthFocus),
      'strengthProgressionExpectation':
          serializer.toJson<String?>(strengthProgressionExpectation),
      'primaryProgressionTarget':
          serializer.toJson<String?>(primaryProgressionTarget),
      'recoveryEmphasis': serializer.toJson<String?>(recoveryEmphasis),
      'deload': serializer.toJson<bool>(deload),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'lastPlanCycleId': serializer.toJson<String?>(lastPlanCycleId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PlanLongRangeWeek copyWith(
          {String? id,
          String? weekLabel,
          Value<int?> weekNumber = const Value.absent(),
          String? weekStart,
          String? weekEnd,
          Value<String?> runFocus = const Value.absent(),
          Value<String?> strengthFocus = const Value.absent(),
          Value<String?> strengthProgressionExpectation = const Value.absent(),
          Value<String?> primaryProgressionTarget = const Value.absent(),
          Value<String?> recoveryEmphasis = const Value.absent(),
          bool? deload,
          Value<String?> notes = const Value.absent(),
          String? source,
          Value<String?> lastPlanCycleId = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      PlanLongRangeWeek(
        id: id ?? this.id,
        weekLabel: weekLabel ?? this.weekLabel,
        weekNumber: weekNumber.present ? weekNumber.value : this.weekNumber,
        weekStart: weekStart ?? this.weekStart,
        weekEnd: weekEnd ?? this.weekEnd,
        runFocus: runFocus.present ? runFocus.value : this.runFocus,
        strengthFocus:
            strengthFocus.present ? strengthFocus.value : this.strengthFocus,
        strengthProgressionExpectation: strengthProgressionExpectation.present
            ? strengthProgressionExpectation.value
            : this.strengthProgressionExpectation,
        primaryProgressionTarget: primaryProgressionTarget.present
            ? primaryProgressionTarget.value
            : this.primaryProgressionTarget,
        recoveryEmphasis: recoveryEmphasis.present
            ? recoveryEmphasis.value
            : this.recoveryEmphasis,
        deload: deload ?? this.deload,
        notes: notes.present ? notes.value : this.notes,
        source: source ?? this.source,
        lastPlanCycleId: lastPlanCycleId.present
            ? lastPlanCycleId.value
            : this.lastPlanCycleId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PlanLongRangeWeek copyWithCompanion(PlanLongRangeWeeksCompanion data) {
    return PlanLongRangeWeek(
      id: data.id.present ? data.id.value : this.id,
      weekLabel: data.weekLabel.present ? data.weekLabel.value : this.weekLabel,
      weekNumber:
          data.weekNumber.present ? data.weekNumber.value : this.weekNumber,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weekEnd: data.weekEnd.present ? data.weekEnd.value : this.weekEnd,
      runFocus: data.runFocus.present ? data.runFocus.value : this.runFocus,
      strengthFocus: data.strengthFocus.present
          ? data.strengthFocus.value
          : this.strengthFocus,
      strengthProgressionExpectation:
          data.strengthProgressionExpectation.present
              ? data.strengthProgressionExpectation.value
              : this.strengthProgressionExpectation,
      primaryProgressionTarget: data.primaryProgressionTarget.present
          ? data.primaryProgressionTarget.value
          : this.primaryProgressionTarget,
      recoveryEmphasis: data.recoveryEmphasis.present
          ? data.recoveryEmphasis.value
          : this.recoveryEmphasis,
      deload: data.deload.present ? data.deload.value : this.deload,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      lastPlanCycleId: data.lastPlanCycleId.present
          ? data.lastPlanCycleId.value
          : this.lastPlanCycleId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanLongRangeWeek(')
          ..write('id: $id, ')
          ..write('weekLabel: $weekLabel, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('runFocus: $runFocus, ')
          ..write('strengthFocus: $strengthFocus, ')
          ..write(
              'strengthProgressionExpectation: $strengthProgressionExpectation, ')
          ..write('primaryProgressionTarget: $primaryProgressionTarget, ')
          ..write('recoveryEmphasis: $recoveryEmphasis, ')
          ..write('deload: $deload, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('lastPlanCycleId: $lastPlanCycleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      weekLabel,
      weekNumber,
      weekStart,
      weekEnd,
      runFocus,
      strengthFocus,
      strengthProgressionExpectation,
      primaryProgressionTarget,
      recoveryEmphasis,
      deload,
      notes,
      source,
      lastPlanCycleId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLongRangeWeek &&
          other.id == this.id &&
          other.weekLabel == this.weekLabel &&
          other.weekNumber == this.weekNumber &&
          other.weekStart == this.weekStart &&
          other.weekEnd == this.weekEnd &&
          other.runFocus == this.runFocus &&
          other.strengthFocus == this.strengthFocus &&
          other.strengthProgressionExpectation ==
              this.strengthProgressionExpectation &&
          other.primaryProgressionTarget == this.primaryProgressionTarget &&
          other.recoveryEmphasis == this.recoveryEmphasis &&
          other.deload == this.deload &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.lastPlanCycleId == this.lastPlanCycleId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlanLongRangeWeeksCompanion extends UpdateCompanion<PlanLongRangeWeek> {
  final Value<String> id;
  final Value<String> weekLabel;
  final Value<int?> weekNumber;
  final Value<String> weekStart;
  final Value<String> weekEnd;
  final Value<String?> runFocus;
  final Value<String?> strengthFocus;
  final Value<String?> strengthProgressionExpectation;
  final Value<String?> primaryProgressionTarget;
  final Value<String?> recoveryEmphasis;
  final Value<bool> deload;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> lastPlanCycleId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PlanLongRangeWeeksCompanion({
    this.id = const Value.absent(),
    this.weekLabel = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.weekEnd = const Value.absent(),
    this.runFocus = const Value.absent(),
    this.strengthFocus = const Value.absent(),
    this.strengthProgressionExpectation = const Value.absent(),
    this.primaryProgressionTarget = const Value.absent(),
    this.recoveryEmphasis = const Value.absent(),
    this.deload = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.lastPlanCycleId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLongRangeWeeksCompanion.insert({
    required String id,
    required String weekLabel,
    this.weekNumber = const Value.absent(),
    required String weekStart,
    required String weekEnd,
    this.runFocus = const Value.absent(),
    this.strengthFocus = const Value.absent(),
    this.strengthProgressionExpectation = const Value.absent(),
    this.primaryProgressionTarget = const Value.absent(),
    this.recoveryEmphasis = const Value.absent(),
    this.deload = const Value.absent(),
    this.notes = const Value.absent(),
    required String source,
    this.lastPlanCycleId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        weekLabel = Value(weekLabel),
        weekStart = Value(weekStart),
        weekEnd = Value(weekEnd),
        source = Value(source),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PlanLongRangeWeek> custom({
    Expression<String>? id,
    Expression<String>? weekLabel,
    Expression<int>? weekNumber,
    Expression<String>? weekStart,
    Expression<String>? weekEnd,
    Expression<String>? runFocus,
    Expression<String>? strengthFocus,
    Expression<String>? strengthProgressionExpectation,
    Expression<String>? primaryProgressionTarget,
    Expression<String>? recoveryEmphasis,
    Expression<bool>? deload,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? lastPlanCycleId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekLabel != null) 'week_label': weekLabel,
      if (weekNumber != null) 'week_number': weekNumber,
      if (weekStart != null) 'week_start': weekStart,
      if (weekEnd != null) 'week_end': weekEnd,
      if (runFocus != null) 'run_focus': runFocus,
      if (strengthFocus != null) 'strength_focus': strengthFocus,
      if (strengthProgressionExpectation != null)
        'strength_progression_expectation': strengthProgressionExpectation,
      if (primaryProgressionTarget != null)
        'primary_progression_target': primaryProgressionTarget,
      if (recoveryEmphasis != null) 'recovery_emphasis': recoveryEmphasis,
      if (deload != null) 'deload': deload,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (lastPlanCycleId != null) 'last_plan_cycle_id': lastPlanCycleId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanLongRangeWeeksCompanion copyWith(
      {Value<String>? id,
      Value<String>? weekLabel,
      Value<int?>? weekNumber,
      Value<String>? weekStart,
      Value<String>? weekEnd,
      Value<String?>? runFocus,
      Value<String?>? strengthFocus,
      Value<String?>? strengthProgressionExpectation,
      Value<String?>? primaryProgressionTarget,
      Value<String?>? recoveryEmphasis,
      Value<bool>? deload,
      Value<String?>? notes,
      Value<String>? source,
      Value<String?>? lastPlanCycleId,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return PlanLongRangeWeeksCompanion(
      id: id ?? this.id,
      weekLabel: weekLabel ?? this.weekLabel,
      weekNumber: weekNumber ?? this.weekNumber,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      runFocus: runFocus ?? this.runFocus,
      strengthFocus: strengthFocus ?? this.strengthFocus,
      strengthProgressionExpectation:
          strengthProgressionExpectation ?? this.strengthProgressionExpectation,
      primaryProgressionTarget:
          primaryProgressionTarget ?? this.primaryProgressionTarget,
      recoveryEmphasis: recoveryEmphasis ?? this.recoveryEmphasis,
      deload: deload ?? this.deload,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      lastPlanCycleId: lastPlanCycleId ?? this.lastPlanCycleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (weekLabel.present) {
      map['week_label'] = Variable<String>(weekLabel.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (weekEnd.present) {
      map['week_end'] = Variable<String>(weekEnd.value);
    }
    if (runFocus.present) {
      map['run_focus'] = Variable<String>(runFocus.value);
    }
    if (strengthFocus.present) {
      map['strength_focus'] = Variable<String>(strengthFocus.value);
    }
    if (strengthProgressionExpectation.present) {
      map['strength_progression_expectation'] =
          Variable<String>(strengthProgressionExpectation.value);
    }
    if (primaryProgressionTarget.present) {
      map['primary_progression_target'] =
          Variable<String>(primaryProgressionTarget.value);
    }
    if (recoveryEmphasis.present) {
      map['recovery_emphasis'] = Variable<String>(recoveryEmphasis.value);
    }
    if (deload.present) {
      map['deload'] = Variable<bool>(deload.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lastPlanCycleId.present) {
      map['last_plan_cycle_id'] = Variable<String>(lastPlanCycleId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanLongRangeWeeksCompanion(')
          ..write('id: $id, ')
          ..write('weekLabel: $weekLabel, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('runFocus: $runFocus, ')
          ..write('strengthFocus: $strengthFocus, ')
          ..write(
              'strengthProgressionExpectation: $strengthProgressionExpectation, ')
          ..write('primaryProgressionTarget: $primaryProgressionTarget, ')
          ..write('recoveryEmphasis: $recoveryEmphasis, ')
          ..write('deload: $deload, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('lastPlanCycleId: $lastPlanCycleId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanLongRangeWeekPerformanceTable extends PlanLongRangeWeekPerformance
    with
        TableInfo<$PlanLongRangeWeekPerformanceTable,
            PlanLongRangeWeekPerformanceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanLongRangeWeekPerformanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planLongRangeWeekIdMeta =
      const VerificationMeta('planLongRangeWeekId');
  @override
  late final GeneratedColumn<String> planLongRangeWeekId =
      GeneratedColumn<String>('plan_long_range_week_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weekLabelMeta =
      const VerificationMeta('weekLabel');
  @override
  late final GeneratedColumn<String> weekLabel = GeneratedColumn<String>(
      'week_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weekNumberMeta =
      const VerificationMeta('weekNumber');
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
      'week_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
      'week_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekEndMeta =
      const VerificationMeta('weekEnd');
  @override
  late final GeneratedColumn<String> weekEnd = GeneratedColumn<String>(
      'week_end', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evaluatedPlanCycleIdMeta =
      const VerificationMeta('evaluatedPlanCycleId');
  @override
  late final GeneratedColumn<String> evaluatedPlanCycleId =
      GeneratedColumn<String>('evaluated_plan_cycle_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _evaluationSourceMeta =
      const VerificationMeta('evaluationSource');
  @override
  late final GeneratedColumn<String> evaluationSource = GeneratedColumn<String>(
      'evaluation_source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plannedDayCountMeta =
      const VerificationMeta('plannedDayCount');
  @override
  late final GeneratedColumn<int> plannedDayCount = GeneratedColumn<int>(
      'planned_day_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedPlanDaysMeta =
      const VerificationMeta('completedPlanDays');
  @override
  late final GeneratedColumn<int> completedPlanDays = GeneratedColumn<int>(
      'completed_plan_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _plannedRunDaysMeta =
      const VerificationMeta('plannedRunDays');
  @override
  late final GeneratedColumn<int> plannedRunDays = GeneratedColumn<int>(
      'planned_run_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualRunDaysMeta =
      const VerificationMeta('actualRunDays');
  @override
  late final GeneratedColumn<int> actualRunDays = GeneratedColumn<int>(
      'actual_run_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _plannedRunSessionsMeta =
      const VerificationMeta('plannedRunSessions');
  @override
  late final GeneratedColumn<int> plannedRunSessions = GeneratedColumn<int>(
      'planned_run_sessions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualRunSessionsMeta =
      const VerificationMeta('actualRunSessions');
  @override
  late final GeneratedColumn<int> actualRunSessions = GeneratedColumn<int>(
      'actual_run_sessions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _plannedStrengthExercisesMeta =
      const VerificationMeta('plannedStrengthExercises');
  @override
  late final GeneratedColumn<int> plannedStrengthExercises =
      GeneratedColumn<int>('planned_strength_exercises', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualStrengthExercisesMeta =
      const VerificationMeta('actualStrengthExercises');
  @override
  late final GeneratedColumn<int> actualStrengthExercises =
      GeneratedColumn<int>('actual_strength_exercises', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _plannedStrengthSetsMeta =
      const VerificationMeta('plannedStrengthSets');
  @override
  late final GeneratedColumn<int> plannedStrengthSets = GeneratedColumn<int>(
      'planned_strength_sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualStrengthSetsMeta =
      const VerificationMeta('actualStrengthSets');
  @override
  late final GeneratedColumn<int> actualStrengthSets = GeneratedColumn<int>(
      'actual_strength_sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _strengthProgressionExpectationMeta =
      const VerificationMeta('strengthProgressionExpectation');
  @override
  late final GeneratedColumn<String> strengthProgressionExpectation =
      GeneratedColumn<String>(
          'strength_progression_expectation', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strengthProgressionEvaluationMeta =
      const VerificationMeta('strengthProgressionEvaluation');
  @override
  late final GeneratedColumn<String> strengthProgressionEvaluation =
      GeneratedColumn<String>(
          'strength_progression_evaluation', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actualRunDistanceMMeta =
      const VerificationMeta('actualRunDistanceM');
  @override
  late final GeneratedColumn<double> actualRunDistanceM =
      GeneratedColumn<double>('actual_run_distance_m', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _actualRunDurationSMeta =
      const VerificationMeta('actualRunDurationS');
  @override
  late final GeneratedColumn<int> actualRunDurationS = GeneratedColumn<int>(
      'actual_run_duration_s', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _metricsJsonMeta =
      const VerificationMeta('metricsJson');
  @override
  late final GeneratedColumn<String> metricsJson = GeneratedColumn<String>(
      'metrics_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<int> capturedAt = GeneratedColumn<int>(
      'captured_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planLongRangeWeekId,
        weekLabel,
        weekNumber,
        weekStart,
        weekEnd,
        evaluatedPlanCycleId,
        evaluationSource,
        plannedDayCount,
        completedPlanDays,
        plannedRunDays,
        actualRunDays,
        plannedRunSessions,
        actualRunSessions,
        plannedStrengthExercises,
        actualStrengthExercises,
        plannedStrengthSets,
        actualStrengthSets,
        strengthProgressionExpectation,
        strengthProgressionEvaluation,
        actualRunDistanceM,
        actualRunDurationS,
        metricsJson,
        capturedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_long_range_week_performance';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlanLongRangeWeekPerformanceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_long_range_week_id')) {
      context.handle(
          _planLongRangeWeekIdMeta,
          planLongRangeWeekId.isAcceptableOrUnknown(
              data['plan_long_range_week_id']!, _planLongRangeWeekIdMeta));
    }
    if (data.containsKey('week_label')) {
      context.handle(_weekLabelMeta,
          weekLabel.isAcceptableOrUnknown(data['week_label']!, _weekLabelMeta));
    }
    if (data.containsKey('week_number')) {
      context.handle(
          _weekNumberMeta,
          weekNumber.isAcceptableOrUnknown(
              data['week_number']!, _weekNumberMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('week_end')) {
      context.handle(_weekEndMeta,
          weekEnd.isAcceptableOrUnknown(data['week_end']!, _weekEndMeta));
    } else if (isInserting) {
      context.missing(_weekEndMeta);
    }
    if (data.containsKey('evaluated_plan_cycle_id')) {
      context.handle(
          _evaluatedPlanCycleIdMeta,
          evaluatedPlanCycleId.isAcceptableOrUnknown(
              data['evaluated_plan_cycle_id']!, _evaluatedPlanCycleIdMeta));
    }
    if (data.containsKey('evaluation_source')) {
      context.handle(
          _evaluationSourceMeta,
          evaluationSource.isAcceptableOrUnknown(
              data['evaluation_source']!, _evaluationSourceMeta));
    } else if (isInserting) {
      context.missing(_evaluationSourceMeta);
    }
    if (data.containsKey('planned_day_count')) {
      context.handle(
          _plannedDayCountMeta,
          plannedDayCount.isAcceptableOrUnknown(
              data['planned_day_count']!, _plannedDayCountMeta));
    } else if (isInserting) {
      context.missing(_plannedDayCountMeta);
    }
    if (data.containsKey('completed_plan_days')) {
      context.handle(
          _completedPlanDaysMeta,
          completedPlanDays.isAcceptableOrUnknown(
              data['completed_plan_days']!, _completedPlanDaysMeta));
    } else if (isInserting) {
      context.missing(_completedPlanDaysMeta);
    }
    if (data.containsKey('planned_run_days')) {
      context.handle(
          _plannedRunDaysMeta,
          plannedRunDays.isAcceptableOrUnknown(
              data['planned_run_days']!, _plannedRunDaysMeta));
    } else if (isInserting) {
      context.missing(_plannedRunDaysMeta);
    }
    if (data.containsKey('actual_run_days')) {
      context.handle(
          _actualRunDaysMeta,
          actualRunDays.isAcceptableOrUnknown(
              data['actual_run_days']!, _actualRunDaysMeta));
    } else if (isInserting) {
      context.missing(_actualRunDaysMeta);
    }
    if (data.containsKey('planned_run_sessions')) {
      context.handle(
          _plannedRunSessionsMeta,
          plannedRunSessions.isAcceptableOrUnknown(
              data['planned_run_sessions']!, _plannedRunSessionsMeta));
    } else if (isInserting) {
      context.missing(_plannedRunSessionsMeta);
    }
    if (data.containsKey('actual_run_sessions')) {
      context.handle(
          _actualRunSessionsMeta,
          actualRunSessions.isAcceptableOrUnknown(
              data['actual_run_sessions']!, _actualRunSessionsMeta));
    } else if (isInserting) {
      context.missing(_actualRunSessionsMeta);
    }
    if (data.containsKey('planned_strength_exercises')) {
      context.handle(
          _plannedStrengthExercisesMeta,
          plannedStrengthExercises.isAcceptableOrUnknown(
              data['planned_strength_exercises']!,
              _plannedStrengthExercisesMeta));
    } else if (isInserting) {
      context.missing(_plannedStrengthExercisesMeta);
    }
    if (data.containsKey('actual_strength_exercises')) {
      context.handle(
          _actualStrengthExercisesMeta,
          actualStrengthExercises.isAcceptableOrUnknown(
              data['actual_strength_exercises']!,
              _actualStrengthExercisesMeta));
    } else if (isInserting) {
      context.missing(_actualStrengthExercisesMeta);
    }
    if (data.containsKey('planned_strength_sets')) {
      context.handle(
          _plannedStrengthSetsMeta,
          plannedStrengthSets.isAcceptableOrUnknown(
              data['planned_strength_sets']!, _plannedStrengthSetsMeta));
    } else if (isInserting) {
      context.missing(_plannedStrengthSetsMeta);
    }
    if (data.containsKey('actual_strength_sets')) {
      context.handle(
          _actualStrengthSetsMeta,
          actualStrengthSets.isAcceptableOrUnknown(
              data['actual_strength_sets']!, _actualStrengthSetsMeta));
    } else if (isInserting) {
      context.missing(_actualStrengthSetsMeta);
    }
    if (data.containsKey('strength_progression_expectation')) {
      context.handle(
          _strengthProgressionExpectationMeta,
          strengthProgressionExpectation.isAcceptableOrUnknown(
              data['strength_progression_expectation']!,
              _strengthProgressionExpectationMeta));
    }
    if (data.containsKey('strength_progression_evaluation')) {
      context.handle(
          _strengthProgressionEvaluationMeta,
          strengthProgressionEvaluation.isAcceptableOrUnknown(
              data['strength_progression_evaluation']!,
              _strengthProgressionEvaluationMeta));
    }
    if (data.containsKey('actual_run_distance_m')) {
      context.handle(
          _actualRunDistanceMMeta,
          actualRunDistanceM.isAcceptableOrUnknown(
              data['actual_run_distance_m']!, _actualRunDistanceMMeta));
    }
    if (data.containsKey('actual_run_duration_s')) {
      context.handle(
          _actualRunDurationSMeta,
          actualRunDurationS.isAcceptableOrUnknown(
              data['actual_run_duration_s']!, _actualRunDurationSMeta));
    }
    if (data.containsKey('metrics_json')) {
      context.handle(
          _metricsJsonMeta,
          metricsJson.isAcceptableOrUnknown(
              data['metrics_json']!, _metricsJsonMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanLongRangeWeekPerformanceData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanLongRangeWeekPerformanceData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planLongRangeWeekId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}plan_long_range_week_id']),
      weekLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_label']),
      weekNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}week_number']),
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_start'])!,
      weekEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_end'])!,
      evaluatedPlanCycleId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}evaluated_plan_cycle_id']),
      evaluationSource: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}evaluation_source'])!,
      plannedDayCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_day_count'])!,
      completedPlanDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_plan_days'])!,
      plannedRunDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_run_days'])!,
      actualRunDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}actual_run_days'])!,
      plannedRunSessions: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}planned_run_sessions'])!,
      actualRunSessions: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}actual_run_sessions'])!,
      plannedStrengthExercises: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}planned_strength_exercises'])!,
      actualStrengthExercises: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}actual_strength_exercises'])!,
      plannedStrengthSets: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}planned_strength_sets'])!,
      actualStrengthSets: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}actual_strength_sets'])!,
      strengthProgressionExpectation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strength_progression_expectation']),
      strengthProgressionEvaluation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strength_progression_evaluation']),
      actualRunDistanceM: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}actual_run_distance_m']),
      actualRunDurationS: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}actual_run_duration_s']),
      metricsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metrics_json']),
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}captured_at'])!,
    );
  }

  @override
  $PlanLongRangeWeekPerformanceTable createAlias(String alias) {
    return $PlanLongRangeWeekPerformanceTable(attachedDatabase, alias);
  }
}

class PlanLongRangeWeekPerformanceData extends DataClass
    implements Insertable<PlanLongRangeWeekPerformanceData> {
  final String id;
  final String? planLongRangeWeekId;
  final String? weekLabel;
  final int? weekNumber;
  final String weekStart;
  final String weekEnd;
  final String? evaluatedPlanCycleId;
  final String evaluationSource;
  final int plannedDayCount;
  final int completedPlanDays;
  final int plannedRunDays;
  final int actualRunDays;
  final int plannedRunSessions;
  final int actualRunSessions;
  final int plannedStrengthExercises;
  final int actualStrengthExercises;
  final int plannedStrengthSets;
  final int actualStrengthSets;
  final String? strengthProgressionExpectation;
  final String? strengthProgressionEvaluation;
  final double? actualRunDistanceM;
  final int? actualRunDurationS;
  final String? metricsJson;
  final int capturedAt;
  const PlanLongRangeWeekPerformanceData(
      {required this.id,
      this.planLongRangeWeekId,
      this.weekLabel,
      this.weekNumber,
      required this.weekStart,
      required this.weekEnd,
      this.evaluatedPlanCycleId,
      required this.evaluationSource,
      required this.plannedDayCount,
      required this.completedPlanDays,
      required this.plannedRunDays,
      required this.actualRunDays,
      required this.plannedRunSessions,
      required this.actualRunSessions,
      required this.plannedStrengthExercises,
      required this.actualStrengthExercises,
      required this.plannedStrengthSets,
      required this.actualStrengthSets,
      this.strengthProgressionExpectation,
      this.strengthProgressionEvaluation,
      this.actualRunDistanceM,
      this.actualRunDurationS,
      this.metricsJson,
      required this.capturedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || planLongRangeWeekId != null) {
      map['plan_long_range_week_id'] = Variable<String>(planLongRangeWeekId);
    }
    if (!nullToAbsent || weekLabel != null) {
      map['week_label'] = Variable<String>(weekLabel);
    }
    if (!nullToAbsent || weekNumber != null) {
      map['week_number'] = Variable<int>(weekNumber);
    }
    map['week_start'] = Variable<String>(weekStart);
    map['week_end'] = Variable<String>(weekEnd);
    if (!nullToAbsent || evaluatedPlanCycleId != null) {
      map['evaluated_plan_cycle_id'] = Variable<String>(evaluatedPlanCycleId);
    }
    map['evaluation_source'] = Variable<String>(evaluationSource);
    map['planned_day_count'] = Variable<int>(plannedDayCount);
    map['completed_plan_days'] = Variable<int>(completedPlanDays);
    map['planned_run_days'] = Variable<int>(plannedRunDays);
    map['actual_run_days'] = Variable<int>(actualRunDays);
    map['planned_run_sessions'] = Variable<int>(plannedRunSessions);
    map['actual_run_sessions'] = Variable<int>(actualRunSessions);
    map['planned_strength_exercises'] = Variable<int>(plannedStrengthExercises);
    map['actual_strength_exercises'] = Variable<int>(actualStrengthExercises);
    map['planned_strength_sets'] = Variable<int>(plannedStrengthSets);
    map['actual_strength_sets'] = Variable<int>(actualStrengthSets);
    if (!nullToAbsent || strengthProgressionExpectation != null) {
      map['strength_progression_expectation'] =
          Variable<String>(strengthProgressionExpectation);
    }
    if (!nullToAbsent || strengthProgressionEvaluation != null) {
      map['strength_progression_evaluation'] =
          Variable<String>(strengthProgressionEvaluation);
    }
    if (!nullToAbsent || actualRunDistanceM != null) {
      map['actual_run_distance_m'] = Variable<double>(actualRunDistanceM);
    }
    if (!nullToAbsent || actualRunDurationS != null) {
      map['actual_run_duration_s'] = Variable<int>(actualRunDurationS);
    }
    if (!nullToAbsent || metricsJson != null) {
      map['metrics_json'] = Variable<String>(metricsJson);
    }
    map['captured_at'] = Variable<int>(capturedAt);
    return map;
  }

  PlanLongRangeWeekPerformanceCompanion toCompanion(bool nullToAbsent) {
    return PlanLongRangeWeekPerformanceCompanion(
      id: Value(id),
      planLongRangeWeekId: planLongRangeWeekId == null && nullToAbsent
          ? const Value.absent()
          : Value(planLongRangeWeekId),
      weekLabel: weekLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(weekLabel),
      weekNumber: weekNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(weekNumber),
      weekStart: Value(weekStart),
      weekEnd: Value(weekEnd),
      evaluatedPlanCycleId: evaluatedPlanCycleId == null && nullToAbsent
          ? const Value.absent()
          : Value(evaluatedPlanCycleId),
      evaluationSource: Value(evaluationSource),
      plannedDayCount: Value(plannedDayCount),
      completedPlanDays: Value(completedPlanDays),
      plannedRunDays: Value(plannedRunDays),
      actualRunDays: Value(actualRunDays),
      plannedRunSessions: Value(plannedRunSessions),
      actualRunSessions: Value(actualRunSessions),
      plannedStrengthExercises: Value(plannedStrengthExercises),
      actualStrengthExercises: Value(actualStrengthExercises),
      plannedStrengthSets: Value(plannedStrengthSets),
      actualStrengthSets: Value(actualStrengthSets),
      strengthProgressionExpectation:
          strengthProgressionExpectation == null && nullToAbsent
              ? const Value.absent()
              : Value(strengthProgressionExpectation),
      strengthProgressionEvaluation:
          strengthProgressionEvaluation == null && nullToAbsent
              ? const Value.absent()
              : Value(strengthProgressionEvaluation),
      actualRunDistanceM: actualRunDistanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(actualRunDistanceM),
      actualRunDurationS: actualRunDurationS == null && nullToAbsent
          ? const Value.absent()
          : Value(actualRunDurationS),
      metricsJson: metricsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metricsJson),
      capturedAt: Value(capturedAt),
    );
  }

  factory PlanLongRangeWeekPerformanceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanLongRangeWeekPerformanceData(
      id: serializer.fromJson<String>(json['id']),
      planLongRangeWeekId:
          serializer.fromJson<String?>(json['planLongRangeWeekId']),
      weekLabel: serializer.fromJson<String?>(json['weekLabel']),
      weekNumber: serializer.fromJson<int?>(json['weekNumber']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      weekEnd: serializer.fromJson<String>(json['weekEnd']),
      evaluatedPlanCycleId:
          serializer.fromJson<String?>(json['evaluatedPlanCycleId']),
      evaluationSource: serializer.fromJson<String>(json['evaluationSource']),
      plannedDayCount: serializer.fromJson<int>(json['plannedDayCount']),
      completedPlanDays: serializer.fromJson<int>(json['completedPlanDays']),
      plannedRunDays: serializer.fromJson<int>(json['plannedRunDays']),
      actualRunDays: serializer.fromJson<int>(json['actualRunDays']),
      plannedRunSessions: serializer.fromJson<int>(json['plannedRunSessions']),
      actualRunSessions: serializer.fromJson<int>(json['actualRunSessions']),
      plannedStrengthExercises:
          serializer.fromJson<int>(json['plannedStrengthExercises']),
      actualStrengthExercises:
          serializer.fromJson<int>(json['actualStrengthExercises']),
      plannedStrengthSets:
          serializer.fromJson<int>(json['plannedStrengthSets']),
      actualStrengthSets: serializer.fromJson<int>(json['actualStrengthSets']),
      strengthProgressionExpectation:
          serializer.fromJson<String?>(json['strengthProgressionExpectation']),
      strengthProgressionEvaluation:
          serializer.fromJson<String?>(json['strengthProgressionEvaluation']),
      actualRunDistanceM:
          serializer.fromJson<double?>(json['actualRunDistanceM']),
      actualRunDurationS: serializer.fromJson<int?>(json['actualRunDurationS']),
      metricsJson: serializer.fromJson<String?>(json['metricsJson']),
      capturedAt: serializer.fromJson<int>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planLongRangeWeekId': serializer.toJson<String?>(planLongRangeWeekId),
      'weekLabel': serializer.toJson<String?>(weekLabel),
      'weekNumber': serializer.toJson<int?>(weekNumber),
      'weekStart': serializer.toJson<String>(weekStart),
      'weekEnd': serializer.toJson<String>(weekEnd),
      'evaluatedPlanCycleId': serializer.toJson<String?>(evaluatedPlanCycleId),
      'evaluationSource': serializer.toJson<String>(evaluationSource),
      'plannedDayCount': serializer.toJson<int>(plannedDayCount),
      'completedPlanDays': serializer.toJson<int>(completedPlanDays),
      'plannedRunDays': serializer.toJson<int>(plannedRunDays),
      'actualRunDays': serializer.toJson<int>(actualRunDays),
      'plannedRunSessions': serializer.toJson<int>(plannedRunSessions),
      'actualRunSessions': serializer.toJson<int>(actualRunSessions),
      'plannedStrengthExercises':
          serializer.toJson<int>(plannedStrengthExercises),
      'actualStrengthExercises':
          serializer.toJson<int>(actualStrengthExercises),
      'plannedStrengthSets': serializer.toJson<int>(plannedStrengthSets),
      'actualStrengthSets': serializer.toJson<int>(actualStrengthSets),
      'strengthProgressionExpectation':
          serializer.toJson<String?>(strengthProgressionExpectation),
      'strengthProgressionEvaluation':
          serializer.toJson<String?>(strengthProgressionEvaluation),
      'actualRunDistanceM': serializer.toJson<double?>(actualRunDistanceM),
      'actualRunDurationS': serializer.toJson<int?>(actualRunDurationS),
      'metricsJson': serializer.toJson<String?>(metricsJson),
      'capturedAt': serializer.toJson<int>(capturedAt),
    };
  }

  PlanLongRangeWeekPerformanceData copyWith(
          {String? id,
          Value<String?> planLongRangeWeekId = const Value.absent(),
          Value<String?> weekLabel = const Value.absent(),
          Value<int?> weekNumber = const Value.absent(),
          String? weekStart,
          String? weekEnd,
          Value<String?> evaluatedPlanCycleId = const Value.absent(),
          String? evaluationSource,
          int? plannedDayCount,
          int? completedPlanDays,
          int? plannedRunDays,
          int? actualRunDays,
          int? plannedRunSessions,
          int? actualRunSessions,
          int? plannedStrengthExercises,
          int? actualStrengthExercises,
          int? plannedStrengthSets,
          int? actualStrengthSets,
          Value<String?> strengthProgressionExpectation = const Value.absent(),
          Value<String?> strengthProgressionEvaluation = const Value.absent(),
          Value<double?> actualRunDistanceM = const Value.absent(),
          Value<int?> actualRunDurationS = const Value.absent(),
          Value<String?> metricsJson = const Value.absent(),
          int? capturedAt}) =>
      PlanLongRangeWeekPerformanceData(
        id: id ?? this.id,
        planLongRangeWeekId: planLongRangeWeekId.present
            ? planLongRangeWeekId.value
            : this.planLongRangeWeekId,
        weekLabel: weekLabel.present ? weekLabel.value : this.weekLabel,
        weekNumber: weekNumber.present ? weekNumber.value : this.weekNumber,
        weekStart: weekStart ?? this.weekStart,
        weekEnd: weekEnd ?? this.weekEnd,
        evaluatedPlanCycleId: evaluatedPlanCycleId.present
            ? evaluatedPlanCycleId.value
            : this.evaluatedPlanCycleId,
        evaluationSource: evaluationSource ?? this.evaluationSource,
        plannedDayCount: plannedDayCount ?? this.plannedDayCount,
        completedPlanDays: completedPlanDays ?? this.completedPlanDays,
        plannedRunDays: plannedRunDays ?? this.plannedRunDays,
        actualRunDays: actualRunDays ?? this.actualRunDays,
        plannedRunSessions: plannedRunSessions ?? this.plannedRunSessions,
        actualRunSessions: actualRunSessions ?? this.actualRunSessions,
        plannedStrengthExercises:
            plannedStrengthExercises ?? this.plannedStrengthExercises,
        actualStrengthExercises:
            actualStrengthExercises ?? this.actualStrengthExercises,
        plannedStrengthSets: plannedStrengthSets ?? this.plannedStrengthSets,
        actualStrengthSets: actualStrengthSets ?? this.actualStrengthSets,
        strengthProgressionExpectation: strengthProgressionExpectation.present
            ? strengthProgressionExpectation.value
            : this.strengthProgressionExpectation,
        strengthProgressionEvaluation: strengthProgressionEvaluation.present
            ? strengthProgressionEvaluation.value
            : this.strengthProgressionEvaluation,
        actualRunDistanceM: actualRunDistanceM.present
            ? actualRunDistanceM.value
            : this.actualRunDistanceM,
        actualRunDurationS: actualRunDurationS.present
            ? actualRunDurationS.value
            : this.actualRunDurationS,
        metricsJson: metricsJson.present ? metricsJson.value : this.metricsJson,
        capturedAt: capturedAt ?? this.capturedAt,
      );
  PlanLongRangeWeekPerformanceData copyWithCompanion(
      PlanLongRangeWeekPerformanceCompanion data) {
    return PlanLongRangeWeekPerformanceData(
      id: data.id.present ? data.id.value : this.id,
      planLongRangeWeekId: data.planLongRangeWeekId.present
          ? data.planLongRangeWeekId.value
          : this.planLongRangeWeekId,
      weekLabel: data.weekLabel.present ? data.weekLabel.value : this.weekLabel,
      weekNumber:
          data.weekNumber.present ? data.weekNumber.value : this.weekNumber,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      weekEnd: data.weekEnd.present ? data.weekEnd.value : this.weekEnd,
      evaluatedPlanCycleId: data.evaluatedPlanCycleId.present
          ? data.evaluatedPlanCycleId.value
          : this.evaluatedPlanCycleId,
      evaluationSource: data.evaluationSource.present
          ? data.evaluationSource.value
          : this.evaluationSource,
      plannedDayCount: data.plannedDayCount.present
          ? data.plannedDayCount.value
          : this.plannedDayCount,
      completedPlanDays: data.completedPlanDays.present
          ? data.completedPlanDays.value
          : this.completedPlanDays,
      plannedRunDays: data.plannedRunDays.present
          ? data.plannedRunDays.value
          : this.plannedRunDays,
      actualRunDays: data.actualRunDays.present
          ? data.actualRunDays.value
          : this.actualRunDays,
      plannedRunSessions: data.plannedRunSessions.present
          ? data.plannedRunSessions.value
          : this.plannedRunSessions,
      actualRunSessions: data.actualRunSessions.present
          ? data.actualRunSessions.value
          : this.actualRunSessions,
      plannedStrengthExercises: data.plannedStrengthExercises.present
          ? data.plannedStrengthExercises.value
          : this.plannedStrengthExercises,
      actualStrengthExercises: data.actualStrengthExercises.present
          ? data.actualStrengthExercises.value
          : this.actualStrengthExercises,
      plannedStrengthSets: data.plannedStrengthSets.present
          ? data.plannedStrengthSets.value
          : this.plannedStrengthSets,
      actualStrengthSets: data.actualStrengthSets.present
          ? data.actualStrengthSets.value
          : this.actualStrengthSets,
      strengthProgressionExpectation:
          data.strengthProgressionExpectation.present
              ? data.strengthProgressionExpectation.value
              : this.strengthProgressionExpectation,
      strengthProgressionEvaluation: data.strengthProgressionEvaluation.present
          ? data.strengthProgressionEvaluation.value
          : this.strengthProgressionEvaluation,
      actualRunDistanceM: data.actualRunDistanceM.present
          ? data.actualRunDistanceM.value
          : this.actualRunDistanceM,
      actualRunDurationS: data.actualRunDurationS.present
          ? data.actualRunDurationS.value
          : this.actualRunDurationS,
      metricsJson:
          data.metricsJson.present ? data.metricsJson.value : this.metricsJson,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanLongRangeWeekPerformanceData(')
          ..write('id: $id, ')
          ..write('planLongRangeWeekId: $planLongRangeWeekId, ')
          ..write('weekLabel: $weekLabel, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('evaluatedPlanCycleId: $evaluatedPlanCycleId, ')
          ..write('evaluationSource: $evaluationSource, ')
          ..write('plannedDayCount: $plannedDayCount, ')
          ..write('completedPlanDays: $completedPlanDays, ')
          ..write('plannedRunDays: $plannedRunDays, ')
          ..write('actualRunDays: $actualRunDays, ')
          ..write('plannedRunSessions: $plannedRunSessions, ')
          ..write('actualRunSessions: $actualRunSessions, ')
          ..write('plannedStrengthExercises: $plannedStrengthExercises, ')
          ..write('actualStrengthExercises: $actualStrengthExercises, ')
          ..write('plannedStrengthSets: $plannedStrengthSets, ')
          ..write('actualStrengthSets: $actualStrengthSets, ')
          ..write(
              'strengthProgressionExpectation: $strengthProgressionExpectation, ')
          ..write(
              'strengthProgressionEvaluation: $strengthProgressionEvaluation, ')
          ..write('actualRunDistanceM: $actualRunDistanceM, ')
          ..write('actualRunDurationS: $actualRunDurationS, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        planLongRangeWeekId,
        weekLabel,
        weekNumber,
        weekStart,
        weekEnd,
        evaluatedPlanCycleId,
        evaluationSource,
        plannedDayCount,
        completedPlanDays,
        plannedRunDays,
        actualRunDays,
        plannedRunSessions,
        actualRunSessions,
        plannedStrengthExercises,
        actualStrengthExercises,
        plannedStrengthSets,
        actualStrengthSets,
        strengthProgressionExpectation,
        strengthProgressionEvaluation,
        actualRunDistanceM,
        actualRunDurationS,
        metricsJson,
        capturedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLongRangeWeekPerformanceData &&
          other.id == this.id &&
          other.planLongRangeWeekId == this.planLongRangeWeekId &&
          other.weekLabel == this.weekLabel &&
          other.weekNumber == this.weekNumber &&
          other.weekStart == this.weekStart &&
          other.weekEnd == this.weekEnd &&
          other.evaluatedPlanCycleId == this.evaluatedPlanCycleId &&
          other.evaluationSource == this.evaluationSource &&
          other.plannedDayCount == this.plannedDayCount &&
          other.completedPlanDays == this.completedPlanDays &&
          other.plannedRunDays == this.plannedRunDays &&
          other.actualRunDays == this.actualRunDays &&
          other.plannedRunSessions == this.plannedRunSessions &&
          other.actualRunSessions == this.actualRunSessions &&
          other.plannedStrengthExercises == this.plannedStrengthExercises &&
          other.actualStrengthExercises == this.actualStrengthExercises &&
          other.plannedStrengthSets == this.plannedStrengthSets &&
          other.actualStrengthSets == this.actualStrengthSets &&
          other.strengthProgressionExpectation ==
              this.strengthProgressionExpectation &&
          other.strengthProgressionEvaluation ==
              this.strengthProgressionEvaluation &&
          other.actualRunDistanceM == this.actualRunDistanceM &&
          other.actualRunDurationS == this.actualRunDurationS &&
          other.metricsJson == this.metricsJson &&
          other.capturedAt == this.capturedAt);
}

class PlanLongRangeWeekPerformanceCompanion
    extends UpdateCompanion<PlanLongRangeWeekPerformanceData> {
  final Value<String> id;
  final Value<String?> planLongRangeWeekId;
  final Value<String?> weekLabel;
  final Value<int?> weekNumber;
  final Value<String> weekStart;
  final Value<String> weekEnd;
  final Value<String?> evaluatedPlanCycleId;
  final Value<String> evaluationSource;
  final Value<int> plannedDayCount;
  final Value<int> completedPlanDays;
  final Value<int> plannedRunDays;
  final Value<int> actualRunDays;
  final Value<int> plannedRunSessions;
  final Value<int> actualRunSessions;
  final Value<int> plannedStrengthExercises;
  final Value<int> actualStrengthExercises;
  final Value<int> plannedStrengthSets;
  final Value<int> actualStrengthSets;
  final Value<String?> strengthProgressionExpectation;
  final Value<String?> strengthProgressionEvaluation;
  final Value<double?> actualRunDistanceM;
  final Value<int?> actualRunDurationS;
  final Value<String?> metricsJson;
  final Value<int> capturedAt;
  final Value<int> rowid;
  const PlanLongRangeWeekPerformanceCompanion({
    this.id = const Value.absent(),
    this.planLongRangeWeekId = const Value.absent(),
    this.weekLabel = const Value.absent(),
    this.weekNumber = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.weekEnd = const Value.absent(),
    this.evaluatedPlanCycleId = const Value.absent(),
    this.evaluationSource = const Value.absent(),
    this.plannedDayCount = const Value.absent(),
    this.completedPlanDays = const Value.absent(),
    this.plannedRunDays = const Value.absent(),
    this.actualRunDays = const Value.absent(),
    this.plannedRunSessions = const Value.absent(),
    this.actualRunSessions = const Value.absent(),
    this.plannedStrengthExercises = const Value.absent(),
    this.actualStrengthExercises = const Value.absent(),
    this.plannedStrengthSets = const Value.absent(),
    this.actualStrengthSets = const Value.absent(),
    this.strengthProgressionExpectation = const Value.absent(),
    this.strengthProgressionEvaluation = const Value.absent(),
    this.actualRunDistanceM = const Value.absent(),
    this.actualRunDurationS = const Value.absent(),
    this.metricsJson = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanLongRangeWeekPerformanceCompanion.insert({
    required String id,
    this.planLongRangeWeekId = const Value.absent(),
    this.weekLabel = const Value.absent(),
    this.weekNumber = const Value.absent(),
    required String weekStart,
    required String weekEnd,
    this.evaluatedPlanCycleId = const Value.absent(),
    required String evaluationSource,
    required int plannedDayCount,
    required int completedPlanDays,
    required int plannedRunDays,
    required int actualRunDays,
    required int plannedRunSessions,
    required int actualRunSessions,
    required int plannedStrengthExercises,
    required int actualStrengthExercises,
    required int plannedStrengthSets,
    required int actualStrengthSets,
    this.strengthProgressionExpectation = const Value.absent(),
    this.strengthProgressionEvaluation = const Value.absent(),
    this.actualRunDistanceM = const Value.absent(),
    this.actualRunDurationS = const Value.absent(),
    this.metricsJson = const Value.absent(),
    required int capturedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        weekStart = Value(weekStart),
        weekEnd = Value(weekEnd),
        evaluationSource = Value(evaluationSource),
        plannedDayCount = Value(plannedDayCount),
        completedPlanDays = Value(completedPlanDays),
        plannedRunDays = Value(plannedRunDays),
        actualRunDays = Value(actualRunDays),
        plannedRunSessions = Value(plannedRunSessions),
        actualRunSessions = Value(actualRunSessions),
        plannedStrengthExercises = Value(plannedStrengthExercises),
        actualStrengthExercises = Value(actualStrengthExercises),
        plannedStrengthSets = Value(plannedStrengthSets),
        actualStrengthSets = Value(actualStrengthSets),
        capturedAt = Value(capturedAt);
  static Insertable<PlanLongRangeWeekPerformanceData> custom({
    Expression<String>? id,
    Expression<String>? planLongRangeWeekId,
    Expression<String>? weekLabel,
    Expression<int>? weekNumber,
    Expression<String>? weekStart,
    Expression<String>? weekEnd,
    Expression<String>? evaluatedPlanCycleId,
    Expression<String>? evaluationSource,
    Expression<int>? plannedDayCount,
    Expression<int>? completedPlanDays,
    Expression<int>? plannedRunDays,
    Expression<int>? actualRunDays,
    Expression<int>? plannedRunSessions,
    Expression<int>? actualRunSessions,
    Expression<int>? plannedStrengthExercises,
    Expression<int>? actualStrengthExercises,
    Expression<int>? plannedStrengthSets,
    Expression<int>? actualStrengthSets,
    Expression<String>? strengthProgressionExpectation,
    Expression<String>? strengthProgressionEvaluation,
    Expression<double>? actualRunDistanceM,
    Expression<int>? actualRunDurationS,
    Expression<String>? metricsJson,
    Expression<int>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planLongRangeWeekId != null)
        'plan_long_range_week_id': planLongRangeWeekId,
      if (weekLabel != null) 'week_label': weekLabel,
      if (weekNumber != null) 'week_number': weekNumber,
      if (weekStart != null) 'week_start': weekStart,
      if (weekEnd != null) 'week_end': weekEnd,
      if (evaluatedPlanCycleId != null)
        'evaluated_plan_cycle_id': evaluatedPlanCycleId,
      if (evaluationSource != null) 'evaluation_source': evaluationSource,
      if (plannedDayCount != null) 'planned_day_count': plannedDayCount,
      if (completedPlanDays != null) 'completed_plan_days': completedPlanDays,
      if (plannedRunDays != null) 'planned_run_days': plannedRunDays,
      if (actualRunDays != null) 'actual_run_days': actualRunDays,
      if (plannedRunSessions != null)
        'planned_run_sessions': plannedRunSessions,
      if (actualRunSessions != null) 'actual_run_sessions': actualRunSessions,
      if (plannedStrengthExercises != null)
        'planned_strength_exercises': plannedStrengthExercises,
      if (actualStrengthExercises != null)
        'actual_strength_exercises': actualStrengthExercises,
      if (plannedStrengthSets != null)
        'planned_strength_sets': plannedStrengthSets,
      if (actualStrengthSets != null)
        'actual_strength_sets': actualStrengthSets,
      if (strengthProgressionExpectation != null)
        'strength_progression_expectation': strengthProgressionExpectation,
      if (strengthProgressionEvaluation != null)
        'strength_progression_evaluation': strengthProgressionEvaluation,
      if (actualRunDistanceM != null)
        'actual_run_distance_m': actualRunDistanceM,
      if (actualRunDurationS != null)
        'actual_run_duration_s': actualRunDurationS,
      if (metricsJson != null) 'metrics_json': metricsJson,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanLongRangeWeekPerformanceCompanion copyWith(
      {Value<String>? id,
      Value<String?>? planLongRangeWeekId,
      Value<String?>? weekLabel,
      Value<int?>? weekNumber,
      Value<String>? weekStart,
      Value<String>? weekEnd,
      Value<String?>? evaluatedPlanCycleId,
      Value<String>? evaluationSource,
      Value<int>? plannedDayCount,
      Value<int>? completedPlanDays,
      Value<int>? plannedRunDays,
      Value<int>? actualRunDays,
      Value<int>? plannedRunSessions,
      Value<int>? actualRunSessions,
      Value<int>? plannedStrengthExercises,
      Value<int>? actualStrengthExercises,
      Value<int>? plannedStrengthSets,
      Value<int>? actualStrengthSets,
      Value<String?>? strengthProgressionExpectation,
      Value<String?>? strengthProgressionEvaluation,
      Value<double?>? actualRunDistanceM,
      Value<int?>? actualRunDurationS,
      Value<String?>? metricsJson,
      Value<int>? capturedAt,
      Value<int>? rowid}) {
    return PlanLongRangeWeekPerformanceCompanion(
      id: id ?? this.id,
      planLongRangeWeekId: planLongRangeWeekId ?? this.planLongRangeWeekId,
      weekLabel: weekLabel ?? this.weekLabel,
      weekNumber: weekNumber ?? this.weekNumber,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      evaluatedPlanCycleId: evaluatedPlanCycleId ?? this.evaluatedPlanCycleId,
      evaluationSource: evaluationSource ?? this.evaluationSource,
      plannedDayCount: plannedDayCount ?? this.plannedDayCount,
      completedPlanDays: completedPlanDays ?? this.completedPlanDays,
      plannedRunDays: plannedRunDays ?? this.plannedRunDays,
      actualRunDays: actualRunDays ?? this.actualRunDays,
      plannedRunSessions: plannedRunSessions ?? this.plannedRunSessions,
      actualRunSessions: actualRunSessions ?? this.actualRunSessions,
      plannedStrengthExercises:
          plannedStrengthExercises ?? this.plannedStrengthExercises,
      actualStrengthExercises:
          actualStrengthExercises ?? this.actualStrengthExercises,
      plannedStrengthSets: plannedStrengthSets ?? this.plannedStrengthSets,
      actualStrengthSets: actualStrengthSets ?? this.actualStrengthSets,
      strengthProgressionExpectation:
          strengthProgressionExpectation ?? this.strengthProgressionExpectation,
      strengthProgressionEvaluation:
          strengthProgressionEvaluation ?? this.strengthProgressionEvaluation,
      actualRunDistanceM: actualRunDistanceM ?? this.actualRunDistanceM,
      actualRunDurationS: actualRunDurationS ?? this.actualRunDurationS,
      metricsJson: metricsJson ?? this.metricsJson,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planLongRangeWeekId.present) {
      map['plan_long_range_week_id'] =
          Variable<String>(planLongRangeWeekId.value);
    }
    if (weekLabel.present) {
      map['week_label'] = Variable<String>(weekLabel.value);
    }
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (weekEnd.present) {
      map['week_end'] = Variable<String>(weekEnd.value);
    }
    if (evaluatedPlanCycleId.present) {
      map['evaluated_plan_cycle_id'] =
          Variable<String>(evaluatedPlanCycleId.value);
    }
    if (evaluationSource.present) {
      map['evaluation_source'] = Variable<String>(evaluationSource.value);
    }
    if (plannedDayCount.present) {
      map['planned_day_count'] = Variable<int>(plannedDayCount.value);
    }
    if (completedPlanDays.present) {
      map['completed_plan_days'] = Variable<int>(completedPlanDays.value);
    }
    if (plannedRunDays.present) {
      map['planned_run_days'] = Variable<int>(plannedRunDays.value);
    }
    if (actualRunDays.present) {
      map['actual_run_days'] = Variable<int>(actualRunDays.value);
    }
    if (plannedRunSessions.present) {
      map['planned_run_sessions'] = Variable<int>(plannedRunSessions.value);
    }
    if (actualRunSessions.present) {
      map['actual_run_sessions'] = Variable<int>(actualRunSessions.value);
    }
    if (plannedStrengthExercises.present) {
      map['planned_strength_exercises'] =
          Variable<int>(plannedStrengthExercises.value);
    }
    if (actualStrengthExercises.present) {
      map['actual_strength_exercises'] =
          Variable<int>(actualStrengthExercises.value);
    }
    if (plannedStrengthSets.present) {
      map['planned_strength_sets'] = Variable<int>(plannedStrengthSets.value);
    }
    if (actualStrengthSets.present) {
      map['actual_strength_sets'] = Variable<int>(actualStrengthSets.value);
    }
    if (strengthProgressionExpectation.present) {
      map['strength_progression_expectation'] =
          Variable<String>(strengthProgressionExpectation.value);
    }
    if (strengthProgressionEvaluation.present) {
      map['strength_progression_evaluation'] =
          Variable<String>(strengthProgressionEvaluation.value);
    }
    if (actualRunDistanceM.present) {
      map['actual_run_distance_m'] = Variable<double>(actualRunDistanceM.value);
    }
    if (actualRunDurationS.present) {
      map['actual_run_duration_s'] = Variable<int>(actualRunDurationS.value);
    }
    if (metricsJson.present) {
      map['metrics_json'] = Variable<String>(metricsJson.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanLongRangeWeekPerformanceCompanion(')
          ..write('id: $id, ')
          ..write('planLongRangeWeekId: $planLongRangeWeekId, ')
          ..write('weekLabel: $weekLabel, ')
          ..write('weekNumber: $weekNumber, ')
          ..write('weekStart: $weekStart, ')
          ..write('weekEnd: $weekEnd, ')
          ..write('evaluatedPlanCycleId: $evaluatedPlanCycleId, ')
          ..write('evaluationSource: $evaluationSource, ')
          ..write('plannedDayCount: $plannedDayCount, ')
          ..write('completedPlanDays: $completedPlanDays, ')
          ..write('plannedRunDays: $plannedRunDays, ')
          ..write('actualRunDays: $actualRunDays, ')
          ..write('plannedRunSessions: $plannedRunSessions, ')
          ..write('actualRunSessions: $actualRunSessions, ')
          ..write('plannedStrengthExercises: $plannedStrengthExercises, ')
          ..write('actualStrengthExercises: $actualStrengthExercises, ')
          ..write('plannedStrengthSets: $plannedStrengthSets, ')
          ..write('actualStrengthSets: $actualStrengthSets, ')
          ..write(
              'strengthProgressionExpectation: $strengthProgressionExpectation, ')
          ..write(
              'strengthProgressionEvaluation: $strengthProgressionEvaluation, ')
          ..write('actualRunDistanceM: $actualRunDistanceM, ')
          ..write('actualRunDurationS: $actualRunDurationS, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanSummarySnapshotsTable extends PlanSummarySnapshots
    with TableInfo<$PlanSummarySnapshotsTable, PlanSummarySnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanSummarySnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planCycleIdMeta =
      const VerificationMeta('planCycleId');
  @override
  late final GeneratedColumn<String> planCycleId = GeneratedColumn<String>(
      'plan_cycle_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tabNameMeta =
      const VerificationMeta('tabName');
  @override
  late final GeneratedColumn<String> tabName = GeneratedColumn<String>(
      'tab_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _snapshotJsonMeta =
      const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
      'snapshot_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, planCycleId, tabName, snapshotJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_summary_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlanSummarySnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_cycle_id')) {
      context.handle(
          _planCycleIdMeta,
          planCycleId.isAcceptableOrUnknown(
              data['plan_cycle_id']!, _planCycleIdMeta));
    } else if (isInserting) {
      context.missing(_planCycleIdMeta);
    }
    if (data.containsKey('tab_name')) {
      context.handle(_tabNameMeta,
          tabName.isAcceptableOrUnknown(data['tab_name']!, _tabNameMeta));
    } else if (isInserting) {
      context.missing(_tabNameMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
          _snapshotJsonMeta,
          snapshotJson.isAcceptableOrUnknown(
              data['snapshot_json']!, _snapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanSummarySnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanSummarySnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planCycleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_cycle_id'])!,
      tabName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tab_name'])!,
      snapshotJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlanSummarySnapshotsTable createAlias(String alias) {
    return $PlanSummarySnapshotsTable(attachedDatabase, alias);
  }
}

class PlanSummarySnapshot extends DataClass
    implements Insertable<PlanSummarySnapshot> {
  final String id;
  final String planCycleId;
  final String tabName;
  final String snapshotJson;
  final int createdAt;
  const PlanSummarySnapshot(
      {required this.id,
      required this.planCycleId,
      required this.tabName,
      required this.snapshotJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_cycle_id'] = Variable<String>(planCycleId);
    map['tab_name'] = Variable<String>(tabName);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlanSummarySnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PlanSummarySnapshotsCompanion(
      id: Value(id),
      planCycleId: Value(planCycleId),
      tabName: Value(tabName),
      snapshotJson: Value(snapshotJson),
      createdAt: Value(createdAt),
    );
  }

  factory PlanSummarySnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanSummarySnapshot(
      id: serializer.fromJson<String>(json['id']),
      planCycleId: serializer.fromJson<String>(json['planCycleId']),
      tabName: serializer.fromJson<String>(json['tabName']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planCycleId': serializer.toJson<String>(planCycleId),
      'tabName': serializer.toJson<String>(tabName),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PlanSummarySnapshot copyWith(
          {String? id,
          String? planCycleId,
          String? tabName,
          String? snapshotJson,
          int? createdAt}) =>
      PlanSummarySnapshot(
        id: id ?? this.id,
        planCycleId: planCycleId ?? this.planCycleId,
        tabName: tabName ?? this.tabName,
        snapshotJson: snapshotJson ?? this.snapshotJson,
        createdAt: createdAt ?? this.createdAt,
      );
  PlanSummarySnapshot copyWithCompanion(PlanSummarySnapshotsCompanion data) {
    return PlanSummarySnapshot(
      id: data.id.present ? data.id.value : this.id,
      planCycleId:
          data.planCycleId.present ? data.planCycleId.value : this.planCycleId,
      tabName: data.tabName.present ? data.tabName.value : this.tabName,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanSummarySnapshot(')
          ..write('id: $id, ')
          ..write('planCycleId: $planCycleId, ')
          ..write('tabName: $tabName, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planCycleId, tabName, snapshotJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanSummarySnapshot &&
          other.id == this.id &&
          other.planCycleId == this.planCycleId &&
          other.tabName == this.tabName &&
          other.snapshotJson == this.snapshotJson &&
          other.createdAt == this.createdAt);
}

class PlanSummarySnapshotsCompanion
    extends UpdateCompanion<PlanSummarySnapshot> {
  final Value<String> id;
  final Value<String> planCycleId;
  final Value<String> tabName;
  final Value<String> snapshotJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlanSummarySnapshotsCompanion({
    this.id = const Value.absent(),
    this.planCycleId = const Value.absent(),
    this.tabName = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanSummarySnapshotsCompanion.insert({
    required String id,
    required String planCycleId,
    required String tabName,
    required String snapshotJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planCycleId = Value(planCycleId),
        tabName = Value(tabName),
        snapshotJson = Value(snapshotJson),
        createdAt = Value(createdAt);
  static Insertable<PlanSummarySnapshot> custom({
    Expression<String>? id,
    Expression<String>? planCycleId,
    Expression<String>? tabName,
    Expression<String>? snapshotJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planCycleId != null) 'plan_cycle_id': planCycleId,
      if (tabName != null) 'tab_name': tabName,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanSummarySnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? planCycleId,
      Value<String>? tabName,
      Value<String>? snapshotJson,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return PlanSummarySnapshotsCompanion(
      id: id ?? this.id,
      planCycleId: planCycleId ?? this.planCycleId,
      tabName: tabName ?? this.tabName,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planCycleId.present) {
      map['plan_cycle_id'] = Variable<String>(planCycleId.value);
    }
    if (tabName.present) {
      map['tab_name'] = Variable<String>(tabName.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanSummarySnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('planCycleId: $planCycleId, ')
          ..write('tabName: $tabName, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanImportAuditTable extends PlanImportAudit
    with TableInfo<$PlanImportAuditTable, PlanImportAuditData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanImportAuditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _successMeta =
      const VerificationMeta('success');
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
      'success', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("success" IN (0, 1))'));
  static const VerificationMeta _detailsJsonMeta =
      const VerificationMeta('detailsJson');
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
      'details_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conflictReportPathMeta =
      const VerificationMeta('conflictReportPath');
  @override
  late final GeneratedColumn<String> conflictReportPath =
      GeneratedColumn<String>('conflict_report_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, importedAt, fileName, success, detailsJson, conflictReportPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_import_audit';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlanImportAuditData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('success')) {
      context.handle(_successMeta,
          success.isAcceptableOrUnknown(data['success']!, _successMeta));
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('details_json')) {
      context.handle(
          _detailsJsonMeta,
          detailsJson.isAcceptableOrUnknown(
              data['details_json']!, _detailsJsonMeta));
    } else if (isInserting) {
      context.missing(_detailsJsonMeta);
    }
    if (data.containsKey('conflict_report_path')) {
      context.handle(
          _conflictReportPathMeta,
          conflictReportPath.isAcceptableOrUnknown(
              data['conflict_report_path']!, _conflictReportPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanImportAuditData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanImportAuditData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}imported_at'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      success: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}success'])!,
      detailsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}details_json'])!,
      conflictReportPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conflict_report_path']),
    );
  }

  @override
  $PlanImportAuditTable createAlias(String alias) {
    return $PlanImportAuditTable(attachedDatabase, alias);
  }
}

class PlanImportAuditData extends DataClass
    implements Insertable<PlanImportAuditData> {
  final String id;
  final int importedAt;
  final String fileName;
  final bool success;
  final String detailsJson;
  final String? conflictReportPath;
  const PlanImportAuditData(
      {required this.id,
      required this.importedAt,
      required this.fileName,
      required this.success,
      required this.detailsJson,
      this.conflictReportPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['imported_at'] = Variable<int>(importedAt);
    map['file_name'] = Variable<String>(fileName);
    map['success'] = Variable<bool>(success);
    map['details_json'] = Variable<String>(detailsJson);
    if (!nullToAbsent || conflictReportPath != null) {
      map['conflict_report_path'] = Variable<String>(conflictReportPath);
    }
    return map;
  }

  PlanImportAuditCompanion toCompanion(bool nullToAbsent) {
    return PlanImportAuditCompanion(
      id: Value(id),
      importedAt: Value(importedAt),
      fileName: Value(fileName),
      success: Value(success),
      detailsJson: Value(detailsJson),
      conflictReportPath: conflictReportPath == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictReportPath),
    );
  }

  factory PlanImportAuditData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanImportAuditData(
      id: serializer.fromJson<String>(json['id']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
      fileName: serializer.fromJson<String>(json['fileName']),
      success: serializer.fromJson<bool>(json['success']),
      detailsJson: serializer.fromJson<String>(json['detailsJson']),
      conflictReportPath:
          serializer.fromJson<String?>(json['conflictReportPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'importedAt': serializer.toJson<int>(importedAt),
      'fileName': serializer.toJson<String>(fileName),
      'success': serializer.toJson<bool>(success),
      'detailsJson': serializer.toJson<String>(detailsJson),
      'conflictReportPath': serializer.toJson<String?>(conflictReportPath),
    };
  }

  PlanImportAuditData copyWith(
          {String? id,
          int? importedAt,
          String? fileName,
          bool? success,
          String? detailsJson,
          Value<String?> conflictReportPath = const Value.absent()}) =>
      PlanImportAuditData(
        id: id ?? this.id,
        importedAt: importedAt ?? this.importedAt,
        fileName: fileName ?? this.fileName,
        success: success ?? this.success,
        detailsJson: detailsJson ?? this.detailsJson,
        conflictReportPath: conflictReportPath.present
            ? conflictReportPath.value
            : this.conflictReportPath,
      );
  PlanImportAuditData copyWithCompanion(PlanImportAuditCompanion data) {
    return PlanImportAuditData(
      id: data.id.present ? data.id.value : this.id,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      success: data.success.present ? data.success.value : this.success,
      detailsJson:
          data.detailsJson.present ? data.detailsJson.value : this.detailsJson,
      conflictReportPath: data.conflictReportPath.present
          ? data.conflictReportPath.value
          : this.conflictReportPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanImportAuditData(')
          ..write('id: $id, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileName: $fileName, ')
          ..write('success: $success, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('conflictReportPath: $conflictReportPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, importedAt, fileName, success, detailsJson, conflictReportPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanImportAuditData &&
          other.id == this.id &&
          other.importedAt == this.importedAt &&
          other.fileName == this.fileName &&
          other.success == this.success &&
          other.detailsJson == this.detailsJson &&
          other.conflictReportPath == this.conflictReportPath);
}

class PlanImportAuditCompanion extends UpdateCompanion<PlanImportAuditData> {
  final Value<String> id;
  final Value<int> importedAt;
  final Value<String> fileName;
  final Value<bool> success;
  final Value<String> detailsJson;
  final Value<String?> conflictReportPath;
  final Value<int> rowid;
  const PlanImportAuditCompanion({
    this.id = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.fileName = const Value.absent(),
    this.success = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.conflictReportPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanImportAuditCompanion.insert({
    required String id,
    required int importedAt,
    required String fileName,
    required bool success,
    required String detailsJson,
    this.conflictReportPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        importedAt = Value(importedAt),
        fileName = Value(fileName),
        success = Value(success),
        detailsJson = Value(detailsJson);
  static Insertable<PlanImportAuditData> custom({
    Expression<String>? id,
    Expression<int>? importedAt,
    Expression<String>? fileName,
    Expression<bool>? success,
    Expression<String>? detailsJson,
    Expression<String>? conflictReportPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (importedAt != null) 'imported_at': importedAt,
      if (fileName != null) 'file_name': fileName,
      if (success != null) 'success': success,
      if (detailsJson != null) 'details_json': detailsJson,
      if (conflictReportPath != null)
        'conflict_report_path': conflictReportPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanImportAuditCompanion copyWith(
      {Value<String>? id,
      Value<int>? importedAt,
      Value<String>? fileName,
      Value<bool>? success,
      Value<String>? detailsJson,
      Value<String?>? conflictReportPath,
      Value<int>? rowid}) {
    return PlanImportAuditCompanion(
      id: id ?? this.id,
      importedAt: importedAt ?? this.importedAt,
      fileName: fileName ?? this.fileName,
      success: success ?? this.success,
      detailsJson: detailsJson ?? this.detailsJson,
      conflictReportPath: conflictReportPath ?? this.conflictReportPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (conflictReportPath.present) {
      map['conflict_report_path'] = Variable<String>(conflictReportPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanImportAuditCompanion(')
          ..write('id: $id, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileName: $fileName, ')
          ..write('success: $success, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('conflictReportPath: $conflictReportPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudWorkspacesTable extends CloudWorkspaces
    with TableInfo<$CloudWorkspacesTable, CloudWorkspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudWorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, createdByUserId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_workspaces';
  @override
  VerificationContext validateIntegrity(Insertable<CloudWorkspace> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudWorkspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudWorkspace(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
    );
  }

  @override
  $CloudWorkspacesTable createAlias(String alias) {
    return $CloudWorkspacesTable(attachedDatabase, alias);
  }
}

class CloudWorkspace extends DataClass implements Insertable<CloudWorkspace> {
  final String id;
  final String name;
  final int createdAt;
  final String createdByUserId;
  const CloudWorkspace(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.createdByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    return map;
  }

  CloudWorkspacesCompanion toCompanion(bool nullToAbsent) {
    return CloudWorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      createdByUserId: Value(createdByUserId),
    );
  }

  factory CloudWorkspace.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudWorkspace(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
    };
  }

  CloudWorkspace copyWith(
          {String? id,
          String? name,
          int? createdAt,
          String? createdByUserId}) =>
      CloudWorkspace(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
      );
  CloudWorkspace copyWithCompanion(CloudWorkspacesCompanion data) {
    return CloudWorkspace(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspace(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, createdByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudWorkspace &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.createdByUserId == this.createdByUserId);
}

class CloudWorkspacesCompanion extends UpdateCompanion<CloudWorkspace> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<String> createdByUserId;
  final Value<int> rowid;
  const CloudWorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudWorkspacesCompanion.insert({
    required String id,
    required String name,
    required int createdAt,
    required String createdByUserId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        createdByUserId = Value(createdByUserId);
  static Insertable<CloudWorkspace> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudWorkspacesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? createdAt,
      Value<String>? createdByUserId,
      Value<int>? rowid}) {
    return CloudWorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudWorkspaceMembershipsTable extends CloudWorkspaceMemberships
    with TableInfo<$CloudWorkspaceMembershipsTable, CloudWorkspaceMembership> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudWorkspaceMembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userEmailMeta =
      const VerificationMeta('userEmail');
  @override
  late final GeneratedColumn<String> userEmail = GeneratedColumn<String>(
      'user_email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workspaceId,
        userId,
        userEmail,
        displayName,
        role,
        status,
        createdAt,
        createdByUserId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_workspace_memberships';
  @override
  VerificationContext validateIntegrity(
      Insertable<CloudWorkspaceMembership> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_email')) {
      context.handle(_userEmailMeta,
          userEmail.isAcceptableOrUnknown(data['user_email']!, _userEmailMeta));
    } else if (isInserting) {
      context.missing(_userEmailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudWorkspaceMembership map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudWorkspaceMembership(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      userEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_email'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
    );
  }

  @override
  $CloudWorkspaceMembershipsTable createAlias(String alias) {
    return $CloudWorkspaceMembershipsTable(attachedDatabase, alias);
  }
}

class CloudWorkspaceMembership extends DataClass
    implements Insertable<CloudWorkspaceMembership> {
  final String id;
  final String workspaceId;
  final String userId;
  final String userEmail;
  final String? displayName;
  final String role;
  final String status;
  final int createdAt;
  final String createdByUserId;
  const CloudWorkspaceMembership(
      {required this.id,
      required this.workspaceId,
      required this.userId,
      required this.userEmail,
      this.displayName,
      required this.role,
      required this.status,
      required this.createdAt,
      required this.createdByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['user_id'] = Variable<String>(userId);
    map['user_email'] = Variable<String>(userEmail);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    return map;
  }

  CloudWorkspaceMembershipsCompanion toCompanion(bool nullToAbsent) {
    return CloudWorkspaceMembershipsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      userId: Value(userId),
      userEmail: Value(userEmail),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      role: Value(role),
      status: Value(status),
      createdAt: Value(createdAt),
      createdByUserId: Value(createdByUserId),
    );
  }

  factory CloudWorkspaceMembership.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudWorkspaceMembership(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      userId: serializer.fromJson<String>(json['userId']),
      userEmail: serializer.fromJson<String>(json['userEmail']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'userId': serializer.toJson<String>(userId),
      'userEmail': serializer.toJson<String>(userEmail),
      'displayName': serializer.toJson<String?>(displayName),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
    };
  }

  CloudWorkspaceMembership copyWith(
          {String? id,
          String? workspaceId,
          String? userId,
          String? userEmail,
          Value<String?> displayName = const Value.absent(),
          String? role,
          String? status,
          int? createdAt,
          String? createdByUserId}) =>
      CloudWorkspaceMembership(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        userId: userId ?? this.userId,
        userEmail: userEmail ?? this.userEmail,
        displayName: displayName.present ? displayName.value : this.displayName,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
      );
  CloudWorkspaceMembership copyWithCompanion(
      CloudWorkspaceMembershipsCompanion data) {
    return CloudWorkspaceMembership(
      id: data.id.present ? data.id.value : this.id,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      userId: data.userId.present ? data.userId.value : this.userId,
      userEmail: data.userEmail.present ? data.userEmail.value : this.userEmail,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspaceMembership(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('userId: $userId, ')
          ..write('userEmail: $userEmail, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workspaceId, userId, userEmail,
      displayName, role, status, createdAt, createdByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudWorkspaceMembership &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.userId == this.userId &&
          other.userEmail == this.userEmail &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.createdByUserId == this.createdByUserId);
}

class CloudWorkspaceMembershipsCompanion
    extends UpdateCompanion<CloudWorkspaceMembership> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> userId;
  final Value<String> userEmail;
  final Value<String?> displayName;
  final Value<String> role;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<String> createdByUserId;
  final Value<int> rowid;
  const CloudWorkspaceMembershipsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userEmail = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudWorkspaceMembershipsCompanion.insert({
    required String id,
    required String workspaceId,
    required String userId,
    required String userEmail,
    this.displayName = const Value.absent(),
    required String role,
    required String status,
    required int createdAt,
    required String createdByUserId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workspaceId = Value(workspaceId),
        userId = Value(userId),
        userEmail = Value(userEmail),
        role = Value(role),
        status = Value(status),
        createdAt = Value(createdAt),
        createdByUserId = Value(createdByUserId);
  static Insertable<CloudWorkspaceMembership> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? userId,
    Expression<String>? userEmail,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (userId != null) 'user_id': userId,
      if (userEmail != null) 'user_email': userEmail,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudWorkspaceMembershipsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workspaceId,
      Value<String>? userId,
      Value<String>? userEmail,
      Value<String?>? displayName,
      Value<String>? role,
      Value<String>? status,
      Value<int>? createdAt,
      Value<String>? createdByUserId,
      Value<int>? rowid}) {
    return CloudWorkspaceMembershipsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (userEmail.present) {
      map['user_email'] = Variable<String>(userEmail.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspaceMembershipsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('userId: $userId, ')
          ..write('userEmail: $userEmail, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudAthleteProfilesTable extends CloudAthleteProfiles
    with TableInfo<$CloudAthleteProfilesTable, CloudAthleteProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudAthleteProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
      'date_of_birth', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, workspaceId, name, dateOfBirth, notes, createdAt, createdByUserId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_athlete_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<CloudAthleteProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudAthleteProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudAthleteProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_of_birth']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
    );
  }

  @override
  $CloudAthleteProfilesTable createAlias(String alias) {
    return $CloudAthleteProfilesTable(attachedDatabase, alias);
  }
}

class CloudAthleteProfile extends DataClass
    implements Insertable<CloudAthleteProfile> {
  final String id;
  final String workspaceId;
  final String name;
  final String? dateOfBirth;
  final String? notes;
  final int createdAt;
  final String createdByUserId;
  const CloudAthleteProfile(
      {required this.id,
      required this.workspaceId,
      required this.name,
      this.dateOfBirth,
      this.notes,
      required this.createdAt,
      required this.createdByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    return map;
  }

  CloudAthleteProfilesCompanion toCompanion(bool nullToAbsent) {
    return CloudAthleteProfilesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      createdByUserId: Value(createdByUserId),
    );
  }

  factory CloudAthleteProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudAthleteProfile(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      dateOfBirth: serializer.fromJson<String?>(json['dateOfBirth']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'dateOfBirth': serializer.toJson<String?>(dateOfBirth),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
    };
  }

  CloudAthleteProfile copyWith(
          {String? id,
          String? workspaceId,
          String? name,
          Value<String?> dateOfBirth = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          int? createdAt,
          String? createdByUserId}) =>
      CloudAthleteProfile(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
      );
  CloudAthleteProfile copyWithCompanion(CloudAthleteProfilesCompanion data) {
    return CloudAthleteProfile(
      id: data.id.present ? data.id.value : this.id,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudAthleteProfile(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, workspaceId, name, dateOfBirth, notes, createdAt, createdByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudAthleteProfile &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.dateOfBirth == this.dateOfBirth &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.createdByUserId == this.createdByUserId);
}

class CloudAthleteProfilesCompanion
    extends UpdateCompanion<CloudAthleteProfile> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> dateOfBirth;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<String> createdByUserId;
  final Value<int> rowid;
  const CloudAthleteProfilesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudAthleteProfilesCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    this.dateOfBirth = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required String createdByUserId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workspaceId = Value(workspaceId),
        name = Value(name),
        createdAt = Value(createdAt),
        createdByUserId = Value(createdByUserId);
  static Insertable<CloudAthleteProfile> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? dateOfBirth,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudAthleteProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? workspaceId,
      Value<String>? name,
      Value<String?>? dateOfBirth,
      Value<String?>? notes,
      Value<int>? createdAt,
      Value<String>? createdByUserId,
      Value<int>? rowid}) {
    return CloudAthleteProfilesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudAthleteProfilesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudAthleteProfileAssignmentsTable
    extends CloudAthleteProfileAssignments
    with
        TableInfo<$CloudAthleteProfileAssignmentsTable,
            CloudAthleteProfileAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudAthleteProfileAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _athleteProfileIdMeta =
      const VerificationMeta('athleteProfileId');
  @override
  late final GeneratedColumn<String> athleteProfileId = GeneratedColumn<String>(
      'athlete_profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _canViewMeta =
      const VerificationMeta('canView');
  @override
  late final GeneratedColumn<bool> canView = GeneratedColumn<bool>(
      'can_view', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("can_view" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _canEditMeta =
      const VerificationMeta('canEdit');
  @override
  late final GeneratedColumn<bool> canEdit = GeneratedColumn<bool>(
      'can_edit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("can_edit" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workspaceId,
        athleteProfileId,
        userId,
        canView,
        canEdit,
        createdAt,
        createdByUserId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_athlete_profile_assignments';
  @override
  VerificationContext validateIntegrity(
      Insertable<CloudAthleteProfileAssignment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('athlete_profile_id')) {
      context.handle(
          _athleteProfileIdMeta,
          athleteProfileId.isAcceptableOrUnknown(
              data['athlete_profile_id']!, _athleteProfileIdMeta));
    } else if (isInserting) {
      context.missing(_athleteProfileIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('can_view')) {
      context.handle(_canViewMeta,
          canView.isAcceptableOrUnknown(data['can_view']!, _canViewMeta));
    }
    if (data.containsKey('can_edit')) {
      context.handle(_canEditMeta,
          canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudAthleteProfileAssignment map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudAthleteProfileAssignment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      athleteProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}athlete_profile_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      canView: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}can_view'])!,
      canEdit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}can_edit'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
    );
  }

  @override
  $CloudAthleteProfileAssignmentsTable createAlias(String alias) {
    return $CloudAthleteProfileAssignmentsTable(attachedDatabase, alias);
  }
}

class CloudAthleteProfileAssignment extends DataClass
    implements Insertable<CloudAthleteProfileAssignment> {
  final String id;
  final String workspaceId;
  final String athleteProfileId;
  final String userId;
  final bool canView;
  final bool canEdit;
  final int createdAt;
  final String createdByUserId;
  const CloudAthleteProfileAssignment(
      {required this.id,
      required this.workspaceId,
      required this.athleteProfileId,
      required this.userId,
      required this.canView,
      required this.canEdit,
      required this.createdAt,
      required this.createdByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['athlete_profile_id'] = Variable<String>(athleteProfileId);
    map['user_id'] = Variable<String>(userId);
    map['can_view'] = Variable<bool>(canView);
    map['can_edit'] = Variable<bool>(canEdit);
    map['created_at'] = Variable<int>(createdAt);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    return map;
  }

  CloudAthleteProfileAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return CloudAthleteProfileAssignmentsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      athleteProfileId: Value(athleteProfileId),
      userId: Value(userId),
      canView: Value(canView),
      canEdit: Value(canEdit),
      createdAt: Value(createdAt),
      createdByUserId: Value(createdByUserId),
    );
  }

  factory CloudAthleteProfileAssignment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudAthleteProfileAssignment(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      athleteProfileId: serializer.fromJson<String>(json['athleteProfileId']),
      userId: serializer.fromJson<String>(json['userId']),
      canView: serializer.fromJson<bool>(json['canView']),
      canEdit: serializer.fromJson<bool>(json['canEdit']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'athleteProfileId': serializer.toJson<String>(athleteProfileId),
      'userId': serializer.toJson<String>(userId),
      'canView': serializer.toJson<bool>(canView),
      'canEdit': serializer.toJson<bool>(canEdit),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
    };
  }

  CloudAthleteProfileAssignment copyWith(
          {String? id,
          String? workspaceId,
          String? athleteProfileId,
          String? userId,
          bool? canView,
          bool? canEdit,
          int? createdAt,
          String? createdByUserId}) =>
      CloudAthleteProfileAssignment(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        athleteProfileId: athleteProfileId ?? this.athleteProfileId,
        userId: userId ?? this.userId,
        canView: canView ?? this.canView,
        canEdit: canEdit ?? this.canEdit,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
      );
  CloudAthleteProfileAssignment copyWithCompanion(
      CloudAthleteProfileAssignmentsCompanion data) {
    return CloudAthleteProfileAssignment(
      id: data.id.present ? data.id.value : this.id,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      athleteProfileId: data.athleteProfileId.present
          ? data.athleteProfileId.value
          : this.athleteProfileId,
      userId: data.userId.present ? data.userId.value : this.userId,
      canView: data.canView.present ? data.canView.value : this.canView,
      canEdit: data.canEdit.present ? data.canEdit.value : this.canEdit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudAthleteProfileAssignment(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('athleteProfileId: $athleteProfileId, ')
          ..write('userId: $userId, ')
          ..write('canView: $canView, ')
          ..write('canEdit: $canEdit, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workspaceId, athleteProfileId, userId,
      canView, canEdit, createdAt, createdByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudAthleteProfileAssignment &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.athleteProfileId == this.athleteProfileId &&
          other.userId == this.userId &&
          other.canView == this.canView &&
          other.canEdit == this.canEdit &&
          other.createdAt == this.createdAt &&
          other.createdByUserId == this.createdByUserId);
}

class CloudAthleteProfileAssignmentsCompanion
    extends UpdateCompanion<CloudAthleteProfileAssignment> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> athleteProfileId;
  final Value<String> userId;
  final Value<bool> canView;
  final Value<bool> canEdit;
  final Value<int> createdAt;
  final Value<String> createdByUserId;
  final Value<int> rowid;
  const CloudAthleteProfileAssignmentsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.athleteProfileId = const Value.absent(),
    this.userId = const Value.absent(),
    this.canView = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudAthleteProfileAssignmentsCompanion.insert({
    required String id,
    required String workspaceId,
    required String athleteProfileId,
    required String userId,
    this.canView = const Value.absent(),
    this.canEdit = const Value.absent(),
    required int createdAt,
    required String createdByUserId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workspaceId = Value(workspaceId),
        athleteProfileId = Value(athleteProfileId),
        userId = Value(userId),
        createdAt = Value(createdAt),
        createdByUserId = Value(createdByUserId);
  static Insertable<CloudAthleteProfileAssignment> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? athleteProfileId,
    Expression<String>? userId,
    Expression<bool>? canView,
    Expression<bool>? canEdit,
    Expression<int>? createdAt,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (athleteProfileId != null) 'athlete_profile_id': athleteProfileId,
      if (userId != null) 'user_id': userId,
      if (canView != null) 'can_view': canView,
      if (canEdit != null) 'can_edit': canEdit,
      if (createdAt != null) 'created_at': createdAt,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudAthleteProfileAssignmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? workspaceId,
      Value<String>? athleteProfileId,
      Value<String>? userId,
      Value<bool>? canView,
      Value<bool>? canEdit,
      Value<int>? createdAt,
      Value<String>? createdByUserId,
      Value<int>? rowid}) {
    return CloudAthleteProfileAssignmentsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      athleteProfileId: athleteProfileId ?? this.athleteProfileId,
      userId: userId ?? this.userId,
      canView: canView ?? this.canView,
      canEdit: canEdit ?? this.canEdit,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (athleteProfileId.present) {
      map['athlete_profile_id'] = Variable<String>(athleteProfileId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (canView.present) {
      map['can_view'] = Variable<bool>(canView.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<bool>(canEdit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudAthleteProfileAssignmentsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('athleteProfileId: $athleteProfileId, ')
          ..write('userId: $userId, ')
          ..write('canView: $canView, ')
          ..write('canEdit: $canEdit, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudWorkspaceInvitesTable extends CloudWorkspaceInvites
    with TableInfo<$CloudWorkspaceInvitesTable, CloudWorkspaceInvite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudWorkspaceInvitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workspaceIdMeta =
      const VerificationMeta('workspaceId');
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
      'workspace_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assignedProfileIdsJsonMeta =
      const VerificationMeta('assignedProfileIdsJson');
  @override
  late final GeneratedColumn<String> assignedProfileIdsJson =
      GeneratedColumn<String>('assigned_profile_ids_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        workspaceId,
        email,
        role,
        displayName,
        expiresAt,
        status,
        assignedProfileIdsJson,
        createdAt,
        createdByUserId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_workspace_invites';
  @override
  VerificationContext validateIntegrity(
      Insertable<CloudWorkspaceInvite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
          _workspaceIdMeta,
          workspaceId.isAcceptableOrUnknown(
              data['workspace_id']!, _workspaceIdMeta));
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('assigned_profile_ids_json')) {
      context.handle(
          _assignedProfileIdsJsonMeta,
          assignedProfileIdsJson.isAcceptableOrUnknown(
              data['assigned_profile_ids_json']!, _assignedProfileIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_assignedProfileIdsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudWorkspaceInvite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudWorkspaceInvite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workspaceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workspace_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      assignedProfileIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}assigned_profile_ids_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
    );
  }

  @override
  $CloudWorkspaceInvitesTable createAlias(String alias) {
    return $CloudWorkspaceInvitesTable(attachedDatabase, alias);
  }
}

class CloudWorkspaceInvite extends DataClass
    implements Insertable<CloudWorkspaceInvite> {
  final String id;
  final String workspaceId;
  final String email;
  final String role;
  final String? displayName;
  final int expiresAt;
  final String status;
  final String assignedProfileIdsJson;
  final int createdAt;
  final String createdByUserId;
  const CloudWorkspaceInvite(
      {required this.id,
      required this.workspaceId,
      required this.email,
      required this.role,
      this.displayName,
      required this.expiresAt,
      required this.status,
      required this.assignedProfileIdsJson,
      required this.createdAt,
      required this.createdByUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['email'] = Variable<String>(email);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['expires_at'] = Variable<int>(expiresAt);
    map['status'] = Variable<String>(status);
    map['assigned_profile_ids_json'] = Variable<String>(assignedProfileIdsJson);
    map['created_at'] = Variable<int>(createdAt);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    return map;
  }

  CloudWorkspaceInvitesCompanion toCompanion(bool nullToAbsent) {
    return CloudWorkspaceInvitesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      email: Value(email),
      role: Value(role),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      expiresAt: Value(expiresAt),
      status: Value(status),
      assignedProfileIdsJson: Value(assignedProfileIdsJson),
      createdAt: Value(createdAt),
      createdByUserId: Value(createdByUserId),
    );
  }

  factory CloudWorkspaceInvite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudWorkspaceInvite(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      email: serializer.fromJson<String>(json['email']),
      role: serializer.fromJson<String>(json['role']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      status: serializer.fromJson<String>(json['status']),
      assignedProfileIdsJson:
          serializer.fromJson<String>(json['assignedProfileIdsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'email': serializer.toJson<String>(email),
      'role': serializer.toJson<String>(role),
      'displayName': serializer.toJson<String?>(displayName),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'status': serializer.toJson<String>(status),
      'assignedProfileIdsJson':
          serializer.toJson<String>(assignedProfileIdsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
    };
  }

  CloudWorkspaceInvite copyWith(
          {String? id,
          String? workspaceId,
          String? email,
          String? role,
          Value<String?> displayName = const Value.absent(),
          int? expiresAt,
          String? status,
          String? assignedProfileIdsJson,
          int? createdAt,
          String? createdByUserId}) =>
      CloudWorkspaceInvite(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        email: email ?? this.email,
        role: role ?? this.role,
        displayName: displayName.present ? displayName.value : this.displayName,
        expiresAt: expiresAt ?? this.expiresAt,
        status: status ?? this.status,
        assignedProfileIdsJson:
            assignedProfileIdsJson ?? this.assignedProfileIdsJson,
        createdAt: createdAt ?? this.createdAt,
        createdByUserId: createdByUserId ?? this.createdByUserId,
      );
  CloudWorkspaceInvite copyWithCompanion(CloudWorkspaceInvitesCompanion data) {
    return CloudWorkspaceInvite(
      id: data.id.present ? data.id.value : this.id,
      workspaceId:
          data.workspaceId.present ? data.workspaceId.value : this.workspaceId,
      email: data.email.present ? data.email.value : this.email,
      role: data.role.present ? data.role.value : this.role,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      status: data.status.present ? data.status.value : this.status,
      assignedProfileIdsJson: data.assignedProfileIdsJson.present
          ? data.assignedProfileIdsJson.value
          : this.assignedProfileIdsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspaceInvite(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('displayName: $displayName, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('assignedProfileIdsJson: $assignedProfileIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, workspaceId, email, role, displayName,
      expiresAt, status, assignedProfileIdsJson, createdAt, createdByUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudWorkspaceInvite &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.email == this.email &&
          other.role == this.role &&
          other.displayName == this.displayName &&
          other.expiresAt == this.expiresAt &&
          other.status == this.status &&
          other.assignedProfileIdsJson == this.assignedProfileIdsJson &&
          other.createdAt == this.createdAt &&
          other.createdByUserId == this.createdByUserId);
}

class CloudWorkspaceInvitesCompanion
    extends UpdateCompanion<CloudWorkspaceInvite> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> email;
  final Value<String> role;
  final Value<String?> displayName;
  final Value<int> expiresAt;
  final Value<String> status;
  final Value<String> assignedProfileIdsJson;
  final Value<int> createdAt;
  final Value<String> createdByUserId;
  final Value<int> rowid;
  const CloudWorkspaceInvitesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.email = const Value.absent(),
    this.role = const Value.absent(),
    this.displayName = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedProfileIdsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CloudWorkspaceInvitesCompanion.insert({
    required String id,
    required String workspaceId,
    required String email,
    required String role,
    this.displayName = const Value.absent(),
    required int expiresAt,
    required String status,
    required String assignedProfileIdsJson,
    required int createdAt,
    required String createdByUserId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workspaceId = Value(workspaceId),
        email = Value(email),
        role = Value(role),
        expiresAt = Value(expiresAt),
        status = Value(status),
        assignedProfileIdsJson = Value(assignedProfileIdsJson),
        createdAt = Value(createdAt),
        createdByUserId = Value(createdByUserId);
  static Insertable<CloudWorkspaceInvite> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? email,
    Expression<String>? role,
    Expression<String>? displayName,
    Expression<int>? expiresAt,
    Expression<String>? status,
    Expression<String>? assignedProfileIdsJson,
    Expression<int>? createdAt,
    Expression<String>? createdByUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (displayName != null) 'display_name': displayName,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (status != null) 'status': status,
      if (assignedProfileIdsJson != null)
        'assigned_profile_ids_json': assignedProfileIdsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CloudWorkspaceInvitesCompanion copyWith(
      {Value<String>? id,
      Value<String>? workspaceId,
      Value<String>? email,
      Value<String>? role,
      Value<String?>? displayName,
      Value<int>? expiresAt,
      Value<String>? status,
      Value<String>? assignedProfileIdsJson,
      Value<int>? createdAt,
      Value<String>? createdByUserId,
      Value<int>? rowid}) {
    return CloudWorkspaceInvitesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      assignedProfileIdsJson:
          assignedProfileIdsJson ?? this.assignedProfileIdsJson,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedProfileIdsJson.present) {
      map['assigned_profile_ids_json'] =
          Variable<String>(assignedProfileIdsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudWorkspaceInvitesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('email: $email, ')
          ..write('role: $role, ')
          ..write('displayName: $displayName, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('status: $status, ')
          ..write('assignedProfileIdsJson: $assignedProfileIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppContextStateTable extends AppContextState
    with TableInfo<$AppContextStateTable, AppContextStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppContextStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('default'));
  static const VerificationMeta _activeWorkspaceIdMeta =
      const VerificationMeta('activeWorkspaceId');
  @override
  late final GeneratedColumn<String> activeWorkspaceId =
      GeneratedColumn<String>('active_workspace_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeProfileIdMeta =
      const VerificationMeta('activeProfileId');
  @override
  late final GeneratedColumn<String> activeProfileId = GeneratedColumn<String>(
      'active_profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeRoleMeta =
      const VerificationMeta('activeRole');
  @override
  late final GeneratedColumn<String> activeRole = GeneratedColumn<String>(
      'active_role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAuthUserIdMeta =
      const VerificationMeta('lastAuthUserId');
  @override
  late final GeneratedColumn<String> lastAuthUserId = GeneratedColumn<String>(
      'last_auth_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsCloudClaimMeta =
      const VerificationMeta('needsCloudClaim');
  @override
  late final GeneratedColumn<bool> needsCloudClaim = GeneratedColumn<bool>(
      'needs_cloud_claim', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("needs_cloud_claim" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pendingInviteTokenMeta =
      const VerificationMeta('pendingInviteToken');
  @override
  late final GeneratedColumn<String> pendingInviteToken =
      GeneratedColumn<String>('pending_invite_token', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        activeWorkspaceId,
        activeProfileId,
        activeRole,
        lastAuthUserId,
        needsCloudClaim,
        pendingInviteToken,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_context_state';
  @override
  VerificationContext validateIntegrity(
      Insertable<AppContextStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_workspace_id')) {
      context.handle(
          _activeWorkspaceIdMeta,
          activeWorkspaceId.isAcceptableOrUnknown(
              data['active_workspace_id']!, _activeWorkspaceIdMeta));
    }
    if (data.containsKey('active_profile_id')) {
      context.handle(
          _activeProfileIdMeta,
          activeProfileId.isAcceptableOrUnknown(
              data['active_profile_id']!, _activeProfileIdMeta));
    }
    if (data.containsKey('active_role')) {
      context.handle(
          _activeRoleMeta,
          activeRole.isAcceptableOrUnknown(
              data['active_role']!, _activeRoleMeta));
    }
    if (data.containsKey('last_auth_user_id')) {
      context.handle(
          _lastAuthUserIdMeta,
          lastAuthUserId.isAcceptableOrUnknown(
              data['last_auth_user_id']!, _lastAuthUserIdMeta));
    }
    if (data.containsKey('needs_cloud_claim')) {
      context.handle(
          _needsCloudClaimMeta,
          needsCloudClaim.isAcceptableOrUnknown(
              data['needs_cloud_claim']!, _needsCloudClaimMeta));
    }
    if (data.containsKey('pending_invite_token')) {
      context.handle(
          _pendingInviteTokenMeta,
          pendingInviteToken.isAcceptableOrUnknown(
              data['pending_invite_token']!, _pendingInviteTokenMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppContextStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppContextStateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activeWorkspaceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_workspace_id']),
      activeProfileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_profile_id']),
      activeRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}active_role']),
      lastAuthUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_auth_user_id']),
      needsCloudClaim: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}needs_cloud_claim'])!,
      pendingInviteToken: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pending_invite_token']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $AppContextStateTable createAlias(String alias) {
    return $AppContextStateTable(attachedDatabase, alias);
  }
}

class AppContextStateData extends DataClass
    implements Insertable<AppContextStateData> {
  final String id;
  final String? activeWorkspaceId;
  final String? activeProfileId;
  final String? activeRole;
  final String? lastAuthUserId;
  final bool needsCloudClaim;
  final String? pendingInviteToken;
  final int? updatedAt;
  const AppContextStateData(
      {required this.id,
      this.activeWorkspaceId,
      this.activeProfileId,
      this.activeRole,
      this.lastAuthUserId,
      required this.needsCloudClaim,
      this.pendingInviteToken,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || activeWorkspaceId != null) {
      map['active_workspace_id'] = Variable<String>(activeWorkspaceId);
    }
    if (!nullToAbsent || activeProfileId != null) {
      map['active_profile_id'] = Variable<String>(activeProfileId);
    }
    if (!nullToAbsent || activeRole != null) {
      map['active_role'] = Variable<String>(activeRole);
    }
    if (!nullToAbsent || lastAuthUserId != null) {
      map['last_auth_user_id'] = Variable<String>(lastAuthUserId);
    }
    map['needs_cloud_claim'] = Variable<bool>(needsCloudClaim);
    if (!nullToAbsent || pendingInviteToken != null) {
      map['pending_invite_token'] = Variable<String>(pendingInviteToken);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  AppContextStateCompanion toCompanion(bool nullToAbsent) {
    return AppContextStateCompanion(
      id: Value(id),
      activeWorkspaceId: activeWorkspaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeWorkspaceId),
      activeProfileId: activeProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeProfileId),
      activeRole: activeRole == null && nullToAbsent
          ? const Value.absent()
          : Value(activeRole),
      lastAuthUserId: lastAuthUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAuthUserId),
      needsCloudClaim: Value(needsCloudClaim),
      pendingInviteToken: pendingInviteToken == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingInviteToken),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AppContextStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppContextStateData(
      id: serializer.fromJson<String>(json['id']),
      activeWorkspaceId:
          serializer.fromJson<String?>(json['activeWorkspaceId']),
      activeProfileId: serializer.fromJson<String?>(json['activeProfileId']),
      activeRole: serializer.fromJson<String?>(json['activeRole']),
      lastAuthUserId: serializer.fromJson<String?>(json['lastAuthUserId']),
      needsCloudClaim: serializer.fromJson<bool>(json['needsCloudClaim']),
      pendingInviteToken:
          serializer.fromJson<String?>(json['pendingInviteToken']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activeWorkspaceId': serializer.toJson<String?>(activeWorkspaceId),
      'activeProfileId': serializer.toJson<String?>(activeProfileId),
      'activeRole': serializer.toJson<String?>(activeRole),
      'lastAuthUserId': serializer.toJson<String?>(lastAuthUserId),
      'needsCloudClaim': serializer.toJson<bool>(needsCloudClaim),
      'pendingInviteToken': serializer.toJson<String?>(pendingInviteToken),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  AppContextStateData copyWith(
          {String? id,
          Value<String?> activeWorkspaceId = const Value.absent(),
          Value<String?> activeProfileId = const Value.absent(),
          Value<String?> activeRole = const Value.absent(),
          Value<String?> lastAuthUserId = const Value.absent(),
          bool? needsCloudClaim,
          Value<String?> pendingInviteToken = const Value.absent(),
          Value<int?> updatedAt = const Value.absent()}) =>
      AppContextStateData(
        id: id ?? this.id,
        activeWorkspaceId: activeWorkspaceId.present
            ? activeWorkspaceId.value
            : this.activeWorkspaceId,
        activeProfileId: activeProfileId.present
            ? activeProfileId.value
            : this.activeProfileId,
        activeRole: activeRole.present ? activeRole.value : this.activeRole,
        lastAuthUserId:
            lastAuthUserId.present ? lastAuthUserId.value : this.lastAuthUserId,
        needsCloudClaim: needsCloudClaim ?? this.needsCloudClaim,
        pendingInviteToken: pendingInviteToken.present
            ? pendingInviteToken.value
            : this.pendingInviteToken,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  AppContextStateData copyWithCompanion(AppContextStateCompanion data) {
    return AppContextStateData(
      id: data.id.present ? data.id.value : this.id,
      activeWorkspaceId: data.activeWorkspaceId.present
          ? data.activeWorkspaceId.value
          : this.activeWorkspaceId,
      activeProfileId: data.activeProfileId.present
          ? data.activeProfileId.value
          : this.activeProfileId,
      activeRole:
          data.activeRole.present ? data.activeRole.value : this.activeRole,
      lastAuthUserId: data.lastAuthUserId.present
          ? data.lastAuthUserId.value
          : this.lastAuthUserId,
      needsCloudClaim: data.needsCloudClaim.present
          ? data.needsCloudClaim.value
          : this.needsCloudClaim,
      pendingInviteToken: data.pendingInviteToken.present
          ? data.pendingInviteToken.value
          : this.pendingInviteToken,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppContextStateData(')
          ..write('id: $id, ')
          ..write('activeWorkspaceId: $activeWorkspaceId, ')
          ..write('activeProfileId: $activeProfileId, ')
          ..write('activeRole: $activeRole, ')
          ..write('lastAuthUserId: $lastAuthUserId, ')
          ..write('needsCloudClaim: $needsCloudClaim, ')
          ..write('pendingInviteToken: $pendingInviteToken, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      activeWorkspaceId,
      activeProfileId,
      activeRole,
      lastAuthUserId,
      needsCloudClaim,
      pendingInviteToken,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppContextStateData &&
          other.id == this.id &&
          other.activeWorkspaceId == this.activeWorkspaceId &&
          other.activeProfileId == this.activeProfileId &&
          other.activeRole == this.activeRole &&
          other.lastAuthUserId == this.lastAuthUserId &&
          other.needsCloudClaim == this.needsCloudClaim &&
          other.pendingInviteToken == this.pendingInviteToken &&
          other.updatedAt == this.updatedAt);
}

class AppContextStateCompanion extends UpdateCompanion<AppContextStateData> {
  final Value<String> id;
  final Value<String?> activeWorkspaceId;
  final Value<String?> activeProfileId;
  final Value<String?> activeRole;
  final Value<String?> lastAuthUserId;
  final Value<bool> needsCloudClaim;
  final Value<String?> pendingInviteToken;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const AppContextStateCompanion({
    this.id = const Value.absent(),
    this.activeWorkspaceId = const Value.absent(),
    this.activeProfileId = const Value.absent(),
    this.activeRole = const Value.absent(),
    this.lastAuthUserId = const Value.absent(),
    this.needsCloudClaim = const Value.absent(),
    this.pendingInviteToken = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppContextStateCompanion.insert({
    this.id = const Value.absent(),
    this.activeWorkspaceId = const Value.absent(),
    this.activeProfileId = const Value.absent(),
    this.activeRole = const Value.absent(),
    this.lastAuthUserId = const Value.absent(),
    this.needsCloudClaim = const Value.absent(),
    this.pendingInviteToken = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AppContextStateData> custom({
    Expression<String>? id,
    Expression<String>? activeWorkspaceId,
    Expression<String>? activeProfileId,
    Expression<String>? activeRole,
    Expression<String>? lastAuthUserId,
    Expression<bool>? needsCloudClaim,
    Expression<String>? pendingInviteToken,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeWorkspaceId != null) 'active_workspace_id': activeWorkspaceId,
      if (activeProfileId != null) 'active_profile_id': activeProfileId,
      if (activeRole != null) 'active_role': activeRole,
      if (lastAuthUserId != null) 'last_auth_user_id': lastAuthUserId,
      if (needsCloudClaim != null) 'needs_cloud_claim': needsCloudClaim,
      if (pendingInviteToken != null)
        'pending_invite_token': pendingInviteToken,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppContextStateCompanion copyWith(
      {Value<String>? id,
      Value<String?>? activeWorkspaceId,
      Value<String?>? activeProfileId,
      Value<String?>? activeRole,
      Value<String?>? lastAuthUserId,
      Value<bool>? needsCloudClaim,
      Value<String?>? pendingInviteToken,
      Value<int?>? updatedAt,
      Value<int>? rowid}) {
    return AppContextStateCompanion(
      id: id ?? this.id,
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      activeRole: activeRole ?? this.activeRole,
      lastAuthUserId: lastAuthUserId ?? this.lastAuthUserId,
      needsCloudClaim: needsCloudClaim ?? this.needsCloudClaim,
      pendingInviteToken: pendingInviteToken ?? this.pendingInviteToken,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activeWorkspaceId.present) {
      map['active_workspace_id'] = Variable<String>(activeWorkspaceId.value);
    }
    if (activeProfileId.present) {
      map['active_profile_id'] = Variable<String>(activeProfileId.value);
    }
    if (activeRole.present) {
      map['active_role'] = Variable<String>(activeRole.value);
    }
    if (lastAuthUserId.present) {
      map['last_auth_user_id'] = Variable<String>(lastAuthUserId.value);
    }
    if (needsCloudClaim.present) {
      map['needs_cloud_claim'] = Variable<bool>(needsCloudClaim.value);
    }
    if (pendingInviteToken.present) {
      map['pending_invite_token'] = Variable<String>(pendingInviteToken.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppContextStateCompanion(')
          ..write('id: $id, ')
          ..write('activeWorkspaceId: $activeWorkspaceId, ')
          ..write('activeProfileId: $activeProfileId, ')
          ..write('activeRole: $activeRole, ')
          ..write('lastAuthUserId: $lastAuthUserId, ')
          ..write('needsCloudClaim: $needsCloudClaim, ')
          ..write('pendingInviteToken: $pendingInviteToken, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $WorkoutDaysTable workoutDays = $WorkoutDaysTable(this);
  late final $ActualStrengthSetsTable actualStrengthSets =
      $ActualStrengthSetsTable(this);
  late final $PrescribedStrengthSetsTable prescribedStrengthSets =
      $PrescribedStrengthSetsTable(this);
  late final $AppPromptTemplatesTable appPromptTemplates =
      $AppPromptTemplatesTable(this);
  late final $SleepNightsTable sleepNights = $SleepNightsTable(this);
  late final $RunSessionsTable runSessions = $RunSessionsTable(this);
  late final $RunSegmentsTable runSegments = $RunSegmentsTable(this);
  late final $RunSessionDetailsTable runSessionDetails =
      $RunSessionDetailsTable(this);
  late final $RunOverrideAuditTable runOverrideAudit =
      $RunOverrideAuditTable(this);
  late final $RuleTriggersTable ruleTriggers = $RuleTriggersTable(this);
  late final $AiAuditTable aiAudit = $AiAuditTable(this);
  late final $ExerciseSubstitutionsTable exerciseSubstitutions =
      $ExerciseSubstitutionsTable(this);
  late final $PlanCyclesTable planCycles = $PlanCyclesTable(this);
  late final $PlanDaysTable planDays = $PlanDaysTable(this);
  late final $PlanExerciseAlternativesTable planExerciseAlternatives =
      $PlanExerciseAlternativesTable(this);
  late final $PlanPrescribedStrengthSetsTable planPrescribedStrengthSets =
      $PlanPrescribedStrengthSetsTable(this);
  late final $PlanPrescribedRunsTable planPrescribedRuns =
      $PlanPrescribedRunsTable(this);
  late final $PlanLongRangeWeeksTable planLongRangeWeeks =
      $PlanLongRangeWeeksTable(this);
  late final $PlanLongRangeWeekPerformanceTable planLongRangeWeekPerformance =
      $PlanLongRangeWeekPerformanceTable(this);
  late final $PlanSummarySnapshotsTable planSummarySnapshots =
      $PlanSummarySnapshotsTable(this);
  late final $PlanImportAuditTable planImportAudit =
      $PlanImportAuditTable(this);
  late final $CloudWorkspacesTable cloudWorkspaces =
      $CloudWorkspacesTable(this);
  late final $CloudWorkspaceMembershipsTable cloudWorkspaceMemberships =
      $CloudWorkspaceMembershipsTable(this);
  late final $CloudAthleteProfilesTable cloudAthleteProfiles =
      $CloudAthleteProfilesTable(this);
  late final $CloudAthleteProfileAssignmentsTable
      cloudAthleteProfileAssignments =
      $CloudAthleteProfileAssignmentsTable(this);
  late final $CloudWorkspaceInvitesTable cloudWorkspaceInvites =
      $CloudWorkspaceInvitesTable(this);
  late final $AppContextStateTable appContextState =
      $AppContextStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        workoutDays,
        actualStrengthSets,
        prescribedStrengthSets,
        appPromptTemplates,
        sleepNights,
        runSessions,
        runSegments,
        runSessionDetails,
        runOverrideAudit,
        ruleTriggers,
        aiAudit,
        exerciseSubstitutions,
        planCycles,
        planDays,
        planExerciseAlternatives,
        planPrescribedStrengthSets,
        planPrescribedRuns,
        planLongRangeWeeks,
        planLongRangeWeekPerformance,
        planSummarySnapshots,
        planImportAudit,
        cloudWorkspaces,
        cloudWorkspaceMemberships,
        cloudAthleteProfiles,
        cloudAthleteProfileAssignments,
        cloudWorkspaceInvites,
        appContextState
      ];
}

typedef $$WorkoutDaysTableCreateCompanionBuilder = WorkoutDaysCompanion
    Function({
  required String id,
  required String workoutDate,
  required int createdAt,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$WorkoutDaysTableUpdateCompanionBuilder = WorkoutDaysCompanion
    Function({
  Value<String> id,
  Value<String> workoutDate,
  Value<int> createdAt,
  Value<String?> notes,
  Value<int> rowid,
});

class $$WorkoutDaysTableFilterComposer
    extends Composer<_$AppDb, $WorkoutDaysTable> {
  $$WorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDate => $composableBuilder(
      column: $table.workoutDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$WorkoutDaysTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutDaysTable> {
  $$WorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDate => $composableBuilder(
      column: $table.workoutDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutDaysTable> {
  $$WorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutDate => $composableBuilder(
      column: $table.workoutDate, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WorkoutDaysTableTableManager extends RootTableManager<
    _$AppDb,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, BaseReferences<_$AppDb, $WorkoutDaysTable, WorkoutDay>),
    WorkoutDay,
    PrefetchHooks Function()> {
  $$WorkoutDaysTableTableManager(_$AppDb db, $WorkoutDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutDate = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutDaysCompanion(
            id: id,
            workoutDate: workoutDate,
            createdAt: createdAt,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutDate,
            required int createdAt,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutDaysCompanion.insert(
            id: id,
            workoutDate: workoutDate,
            createdAt: createdAt,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, BaseReferences<_$AppDb, $WorkoutDaysTable, WorkoutDay>),
    WorkoutDay,
    PrefetchHooks Function()>;
typedef $$ActualStrengthSetsTableCreateCompanionBuilder
    = ActualStrengthSetsCompanion Function({
  required String id,
  required String workoutDayId,
  Value<String?> planDayId,
  Value<int?> performedAt,
  required String exerciseCanonical,
  Value<String?> prescribedExerciseCanonical,
  Value<String?> substitutionId,
  required int setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  required String unit,
  required String source,
  Value<String?> rawSetString,
  required int createdAt,
  Value<int> rowid,
});
typedef $$ActualStrengthSetsTableUpdateCompanionBuilder
    = ActualStrengthSetsCompanion Function({
  Value<String> id,
  Value<String> workoutDayId,
  Value<String?> planDayId,
  Value<int?> performedAt,
  Value<String> exerciseCanonical,
  Value<String?> prescribedExerciseCanonical,
  Value<String?> substitutionId,
  Value<int> setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  Value<String> unit,
  Value<String> source,
  Value<String?> rawSetString,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$ActualStrengthSetsTableFilterComposer
    extends Composer<_$AppDb, $ActualStrengthSetsTable> {
  $$ActualStrengthSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get performedAt => $composableBuilder(
      column: $table.performedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get substitutionId => $composableBuilder(
      column: $table.substitutionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ActualStrengthSetsTableOrderingComposer
    extends Composer<_$AppDb, $ActualStrengthSetsTable> {
  $$ActualStrengthSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get performedAt => $composableBuilder(
      column: $table.performedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get substitutionId => $composableBuilder(
      column: $table.substitutionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ActualStrengthSetsTableAnnotationComposer
    extends Composer<_$AppDb, $ActualStrengthSetsTable> {
  $$ActualStrengthSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<int> get performedAt => $composableBuilder(
      column: $table.performedAt, builder: (column) => column);

  GeneratedColumn<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical, builder: (column) => column);

  GeneratedColumn<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical, builder: (column) => column);

  GeneratedColumn<String> get substitutionId => $composableBuilder(
      column: $table.substitutionId, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ActualStrengthSetsTableTableManager extends RootTableManager<
    _$AppDb,
    $ActualStrengthSetsTable,
    ActualStrengthSet,
    $$ActualStrengthSetsTableFilterComposer,
    $$ActualStrengthSetsTableOrderingComposer,
    $$ActualStrengthSetsTableAnnotationComposer,
    $$ActualStrengthSetsTableCreateCompanionBuilder,
    $$ActualStrengthSetsTableUpdateCompanionBuilder,
    (
      ActualStrengthSet,
      BaseReferences<_$AppDb, $ActualStrengthSetsTable, ActualStrengthSet>
    ),
    ActualStrengthSet,
    PrefetchHooks Function()> {
  $$ActualStrengthSetsTableTableManager(
      _$AppDb db, $ActualStrengthSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActualStrengthSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActualStrengthSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActualStrengthSetsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutDayId = const Value.absent(),
            Value<String?> planDayId = const Value.absent(),
            Value<int?> performedAt = const Value.absent(),
            Value<String> exerciseCanonical = const Value.absent(),
            Value<String?> prescribedExerciseCanonical = const Value.absent(),
            Value<String?> substitutionId = const Value.absent(),
            Value<int> setIndex = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> rawSetString = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActualStrengthSetsCompanion(
            id: id,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            performedAt: performedAt,
            exerciseCanonical: exerciseCanonical,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            substitutionId: substitutionId,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            source: source,
            rawSetString: rawSetString,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutDayId,
            Value<String?> planDayId = const Value.absent(),
            Value<int?> performedAt = const Value.absent(),
            required String exerciseCanonical,
            Value<String?> prescribedExerciseCanonical = const Value.absent(),
            Value<String?> substitutionId = const Value.absent(),
            required int setIndex,
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            required String unit,
            required String source,
            Value<String?> rawSetString = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ActualStrengthSetsCompanion.insert(
            id: id,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            performedAt: performedAt,
            exerciseCanonical: exerciseCanonical,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            substitutionId: substitutionId,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            source: source,
            rawSetString: rawSetString,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActualStrengthSetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $ActualStrengthSetsTable,
    ActualStrengthSet,
    $$ActualStrengthSetsTableFilterComposer,
    $$ActualStrengthSetsTableOrderingComposer,
    $$ActualStrengthSetsTableAnnotationComposer,
    $$ActualStrengthSetsTableCreateCompanionBuilder,
    $$ActualStrengthSetsTableUpdateCompanionBuilder,
    (
      ActualStrengthSet,
      BaseReferences<_$AppDb, $ActualStrengthSetsTable, ActualStrengthSet>
    ),
    ActualStrengthSet,
    PrefetchHooks Function()>;
typedef $$PrescribedStrengthSetsTableCreateCompanionBuilder
    = PrescribedStrengthSetsCompanion Function({
  required String id,
  required String workoutDayId,
  required String exerciseCanonical,
  required int setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  required String unit,
  Value<int> rowid,
});
typedef $$PrescribedStrengthSetsTableUpdateCompanionBuilder
    = PrescribedStrengthSetsCompanion Function({
  Value<String> id,
  Value<String> workoutDayId,
  Value<String> exerciseCanonical,
  Value<int> setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  Value<String> unit,
  Value<int> rowid,
});

class $$PrescribedStrengthSetsTableFilterComposer
    extends Composer<_$AppDb, $PrescribedStrengthSetsTable> {
  $$PrescribedStrengthSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));
}

class $$PrescribedStrengthSetsTableOrderingComposer
    extends Composer<_$AppDb, $PrescribedStrengthSetsTable> {
  $$PrescribedStrengthSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));
}

class $$PrescribedStrengthSetsTableAnnotationComposer
    extends Composer<_$AppDb, $PrescribedStrengthSetsTable> {
  $$PrescribedStrengthSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => column);

  GeneratedColumn<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);
}

class $$PrescribedStrengthSetsTableTableManager extends RootTableManager<
    _$AppDb,
    $PrescribedStrengthSetsTable,
    PrescribedStrengthSet,
    $$PrescribedStrengthSetsTableFilterComposer,
    $$PrescribedStrengthSetsTableOrderingComposer,
    $$PrescribedStrengthSetsTableAnnotationComposer,
    $$PrescribedStrengthSetsTableCreateCompanionBuilder,
    $$PrescribedStrengthSetsTableUpdateCompanionBuilder,
    (
      PrescribedStrengthSet,
      BaseReferences<_$AppDb, $PrescribedStrengthSetsTable,
          PrescribedStrengthSet>
    ),
    PrescribedStrengthSet,
    PrefetchHooks Function()> {
  $$PrescribedStrengthSetsTableTableManager(
      _$AppDb db, $PrescribedStrengthSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescribedStrengthSetsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PrescribedStrengthSetsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrescribedStrengthSetsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutDayId = const Value.absent(),
            Value<String> exerciseCanonical = const Value.absent(),
            Value<int> setIndex = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrescribedStrengthSetsCompanion(
            id: id,
            workoutDayId: workoutDayId,
            exerciseCanonical: exerciseCanonical,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutDayId,
            required String exerciseCanonical,
            required int setIndex,
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            required String unit,
            Value<int> rowid = const Value.absent(),
          }) =>
              PrescribedStrengthSetsCompanion.insert(
            id: id,
            workoutDayId: workoutDayId,
            exerciseCanonical: exerciseCanonical,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PrescribedStrengthSetsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $PrescribedStrengthSetsTable,
        PrescribedStrengthSet,
        $$PrescribedStrengthSetsTableFilterComposer,
        $$PrescribedStrengthSetsTableOrderingComposer,
        $$PrescribedStrengthSetsTableAnnotationComposer,
        $$PrescribedStrengthSetsTableCreateCompanionBuilder,
        $$PrescribedStrengthSetsTableUpdateCompanionBuilder,
        (
          PrescribedStrengthSet,
          BaseReferences<_$AppDb, $PrescribedStrengthSetsTable,
              PrescribedStrengthSet>
        ),
        PrescribedStrengthSet,
        PrefetchHooks Function()>;
typedef $$AppPromptTemplatesTableCreateCompanionBuilder
    = AppPromptTemplatesCompanion Function({
  required String templateKey,
  required String templateText,
  Value<String> source,
  Value<String?> versionTag,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$AppPromptTemplatesTableUpdateCompanionBuilder
    = AppPromptTemplatesCompanion Function({
  Value<String> templateKey,
  Value<String> templateText,
  Value<String> source,
  Value<String?> versionTag,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$AppPromptTemplatesTableFilterComposer
    extends Composer<_$AppDb, $AppPromptTemplatesTable> {
  $$AppPromptTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get templateKey => $composableBuilder(
      column: $table.templateKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateText => $composableBuilder(
      column: $table.templateText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionTag => $composableBuilder(
      column: $table.versionTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppPromptTemplatesTableOrderingComposer
    extends Composer<_$AppDb, $AppPromptTemplatesTable> {
  $$AppPromptTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get templateKey => $composableBuilder(
      column: $table.templateKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateText => $composableBuilder(
      column: $table.templateText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionTag => $composableBuilder(
      column: $table.versionTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppPromptTemplatesTableAnnotationComposer
    extends Composer<_$AppDb, $AppPromptTemplatesTable> {
  $$AppPromptTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get templateKey => $composableBuilder(
      column: $table.templateKey, builder: (column) => column);

  GeneratedColumn<String> get templateText => $composableBuilder(
      column: $table.templateText, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get versionTag => $composableBuilder(
      column: $table.versionTag, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPromptTemplatesTableTableManager extends RootTableManager<
    _$AppDb,
    $AppPromptTemplatesTable,
    AppPromptTemplate,
    $$AppPromptTemplatesTableFilterComposer,
    $$AppPromptTemplatesTableOrderingComposer,
    $$AppPromptTemplatesTableAnnotationComposer,
    $$AppPromptTemplatesTableCreateCompanionBuilder,
    $$AppPromptTemplatesTableUpdateCompanionBuilder,
    (
      AppPromptTemplate,
      BaseReferences<_$AppDb, $AppPromptTemplatesTable, AppPromptTemplate>
    ),
    AppPromptTemplate,
    PrefetchHooks Function()> {
  $$AppPromptTemplatesTableTableManager(
      _$AppDb db, $AppPromptTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPromptTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPromptTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPromptTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> templateKey = const Value.absent(),
            Value<String> templateText = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> versionTag = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppPromptTemplatesCompanion(
            templateKey: templateKey,
            templateText: templateText,
            source: source,
            versionTag: versionTag,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String templateKey,
            required String templateText,
            Value<String> source = const Value.absent(),
            Value<String?> versionTag = const Value.absent(),
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppPromptTemplatesCompanion.insert(
            templateKey: templateKey,
            templateText: templateText,
            source: source,
            versionTag: versionTag,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppPromptTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $AppPromptTemplatesTable,
    AppPromptTemplate,
    $$AppPromptTemplatesTableFilterComposer,
    $$AppPromptTemplatesTableOrderingComposer,
    $$AppPromptTemplatesTableAnnotationComposer,
    $$AppPromptTemplatesTableCreateCompanionBuilder,
    $$AppPromptTemplatesTableUpdateCompanionBuilder,
    (
      AppPromptTemplate,
      BaseReferences<_$AppDb, $AppPromptTemplatesTable, AppPromptTemplate>
    ),
    AppPromptTemplate,
    PrefetchHooks Function()>;
typedef $$SleepNightsTableCreateCompanionBuilder = SleepNightsCompanion
    Function({
  required String id,
  required String sleepDate,
  Value<int?> startTime,
  Value<int?> endTime,
  Value<int?> totalSleepMin,
  Value<int?> remMin,
  Value<int?> deepMin,
  Value<int?> lightMin,
  Value<int?> awakeMin,
  required String source,
  Value<int> rowid,
});
typedef $$SleepNightsTableUpdateCompanionBuilder = SleepNightsCompanion
    Function({
  Value<String> id,
  Value<String> sleepDate,
  Value<int?> startTime,
  Value<int?> endTime,
  Value<int?> totalSleepMin,
  Value<int?> remMin,
  Value<int?> deepMin,
  Value<int?> lightMin,
  Value<int?> awakeMin,
  Value<String> source,
  Value<int> rowid,
});

class $$SleepNightsTableFilterComposer
    extends Composer<_$AppDb, $SleepNightsTable> {
  $$SleepNightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sleepDate => $composableBuilder(
      column: $table.sleepDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSleepMin => $composableBuilder(
      column: $table.totalSleepMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remMin => $composableBuilder(
      column: $table.remMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deepMin => $composableBuilder(
      column: $table.deepMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lightMin => $composableBuilder(
      column: $table.lightMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get awakeMin => $composableBuilder(
      column: $table.awakeMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$SleepNightsTableOrderingComposer
    extends Composer<_$AppDb, $SleepNightsTable> {
  $$SleepNightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sleepDate => $composableBuilder(
      column: $table.sleepDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSleepMin => $composableBuilder(
      column: $table.totalSleepMin,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remMin => $composableBuilder(
      column: $table.remMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deepMin => $composableBuilder(
      column: $table.deepMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lightMin => $composableBuilder(
      column: $table.lightMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get awakeMin => $composableBuilder(
      column: $table.awakeMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$SleepNightsTableAnnotationComposer
    extends Composer<_$AppDb, $SleepNightsTable> {
  $$SleepNightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sleepDate =>
      $composableBuilder(column: $table.sleepDate, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get totalSleepMin => $composableBuilder(
      column: $table.totalSleepMin, builder: (column) => column);

  GeneratedColumn<int> get remMin =>
      $composableBuilder(column: $table.remMin, builder: (column) => column);

  GeneratedColumn<int> get deepMin =>
      $composableBuilder(column: $table.deepMin, builder: (column) => column);

  GeneratedColumn<int> get lightMin =>
      $composableBuilder(column: $table.lightMin, builder: (column) => column);

  GeneratedColumn<int> get awakeMin =>
      $composableBuilder(column: $table.awakeMin, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$SleepNightsTableTableManager extends RootTableManager<
    _$AppDb,
    $SleepNightsTable,
    SleepNight,
    $$SleepNightsTableFilterComposer,
    $$SleepNightsTableOrderingComposer,
    $$SleepNightsTableAnnotationComposer,
    $$SleepNightsTableCreateCompanionBuilder,
    $$SleepNightsTableUpdateCompanionBuilder,
    (SleepNight, BaseReferences<_$AppDb, $SleepNightsTable, SleepNight>),
    SleepNight,
    PrefetchHooks Function()> {
  $$SleepNightsTableTableManager(_$AppDb db, $SleepNightsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepNightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepNightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepNightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sleepDate = const Value.absent(),
            Value<int?> startTime = const Value.absent(),
            Value<int?> endTime = const Value.absent(),
            Value<int?> totalSleepMin = const Value.absent(),
            Value<int?> remMin = const Value.absent(),
            Value<int?> deepMin = const Value.absent(),
            Value<int?> lightMin = const Value.absent(),
            Value<int?> awakeMin = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SleepNightsCompanion(
            id: id,
            sleepDate: sleepDate,
            startTime: startTime,
            endTime: endTime,
            totalSleepMin: totalSleepMin,
            remMin: remMin,
            deepMin: deepMin,
            lightMin: lightMin,
            awakeMin: awakeMin,
            source: source,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sleepDate,
            Value<int?> startTime = const Value.absent(),
            Value<int?> endTime = const Value.absent(),
            Value<int?> totalSleepMin = const Value.absent(),
            Value<int?> remMin = const Value.absent(),
            Value<int?> deepMin = const Value.absent(),
            Value<int?> lightMin = const Value.absent(),
            Value<int?> awakeMin = const Value.absent(),
            required String source,
            Value<int> rowid = const Value.absent(),
          }) =>
              SleepNightsCompanion.insert(
            id: id,
            sleepDate: sleepDate,
            startTime: startTime,
            endTime: endTime,
            totalSleepMin: totalSleepMin,
            remMin: remMin,
            deepMin: deepMin,
            lightMin: lightMin,
            awakeMin: awakeMin,
            source: source,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SleepNightsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $SleepNightsTable,
    SleepNight,
    $$SleepNightsTableFilterComposer,
    $$SleepNightsTableOrderingComposer,
    $$SleepNightsTableAnnotationComposer,
    $$SleepNightsTableCreateCompanionBuilder,
    $$SleepNightsTableUpdateCompanionBuilder,
    (SleepNight, BaseReferences<_$AppDb, $SleepNightsTable, SleepNight>),
    SleepNight,
    PrefetchHooks Function()>;
typedef $$RunSessionsTableCreateCompanionBuilder = RunSessionsCompanion
    Function({
  required String id,
  Value<String> runKey,
  Value<String?> workoutDayId,
  Value<String?> planDayId,
  Value<int?> startTime,
  Value<int?> endTime,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> avgHr,
  Value<double?> maxHr,
  Value<bool?> treadmill,
  Value<String?> title,
  Value<String?> activityType,
  Value<int?> calories,
  Value<int?> movingTimeS,
  Value<int?> elapsedTimeS,
  Value<int> sourcePriority,
  Value<String?> importFileName,
  Value<String?> rawMetricsJson,
  required String source,
  Value<int> rowid,
});
typedef $$RunSessionsTableUpdateCompanionBuilder = RunSessionsCompanion
    Function({
  Value<String> id,
  Value<String> runKey,
  Value<String?> workoutDayId,
  Value<String?> planDayId,
  Value<int?> startTime,
  Value<int?> endTime,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> avgHr,
  Value<double?> maxHr,
  Value<bool?> treadmill,
  Value<String?> title,
  Value<String?> activityType,
  Value<int?> calories,
  Value<int?> movingTimeS,
  Value<int?> elapsedTimeS,
  Value<int> sourcePriority,
  Value<String?> importFileName,
  Value<String?> rawMetricsJson,
  Value<String> source,
  Value<int> rowid,
});

class $$RunSessionsTableFilterComposer
    extends Composer<_$AppDb, $RunSessionsTable> {
  $$RunSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runKey => $composableBuilder(
      column: $table.runKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationS => $composableBuilder(
      column: $table.durationS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxHr => $composableBuilder(
      column: $table.maxHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get treadmill => $composableBuilder(
      column: $table.treadmill, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get movingTimeS => $composableBuilder(
      column: $table.movingTimeS, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedTimeS => $composableBuilder(
      column: $table.elapsedTimeS, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sourcePriority => $composableBuilder(
      column: $table.sourcePriority,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importFileName => $composableBuilder(
      column: $table.importFileName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$RunSessionsTableOrderingComposer
    extends Composer<_$AppDb, $RunSessionsTable> {
  $$RunSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runKey => $composableBuilder(
      column: $table.runKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationS => $composableBuilder(
      column: $table.durationS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgHr => $composableBuilder(
      column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxHr => $composableBuilder(
      column: $table.maxHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get treadmill => $composableBuilder(
      column: $table.treadmill, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityType => $composableBuilder(
      column: $table.activityType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get movingTimeS => $composableBuilder(
      column: $table.movingTimeS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedTimeS => $composableBuilder(
      column: $table.elapsedTimeS,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sourcePriority => $composableBuilder(
      column: $table.sourcePriority,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importFileName => $composableBuilder(
      column: $table.importFileName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$RunSessionsTableAnnotationComposer
    extends Composer<_$AppDb, $RunSessionsTable> {
  $$RunSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runKey =>
      $composableBuilder(column: $table.runKey, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<double> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<bool> get treadmill =>
      $composableBuilder(column: $table.treadmill, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get movingTimeS => $composableBuilder(
      column: $table.movingTimeS, builder: (column) => column);

  GeneratedColumn<int> get elapsedTimeS => $composableBuilder(
      column: $table.elapsedTimeS, builder: (column) => column);

  GeneratedColumn<int> get sourcePriority => $composableBuilder(
      column: $table.sourcePriority, builder: (column) => column);

  GeneratedColumn<String> get importFileName => $composableBuilder(
      column: $table.importFileName, builder: (column) => column);

  GeneratedColumn<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$RunSessionsTableTableManager extends RootTableManager<
    _$AppDb,
    $RunSessionsTable,
    RunSession,
    $$RunSessionsTableFilterComposer,
    $$RunSessionsTableOrderingComposer,
    $$RunSessionsTableAnnotationComposer,
    $$RunSessionsTableCreateCompanionBuilder,
    $$RunSessionsTableUpdateCompanionBuilder,
    (RunSession, BaseReferences<_$AppDb, $RunSessionsTable, RunSession>),
    RunSession,
    PrefetchHooks Function()> {
  $$RunSessionsTableTableManager(_$AppDb db, $RunSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> runKey = const Value.absent(),
            Value<String?> workoutDayId = const Value.absent(),
            Value<String?> planDayId = const Value.absent(),
            Value<int?> startTime = const Value.absent(),
            Value<int?> endTime = const Value.absent(),
            Value<int?> durationS = const Value.absent(),
            Value<double?> distanceM = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<double?> maxHr = const Value.absent(),
            Value<bool?> treadmill = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> activityType = const Value.absent(),
            Value<int?> calories = const Value.absent(),
            Value<int?> movingTimeS = const Value.absent(),
            Value<int?> elapsedTimeS = const Value.absent(),
            Value<int> sourcePriority = const Value.absent(),
            Value<String?> importFileName = const Value.absent(),
            Value<String?> rawMetricsJson = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSessionsCompanion(
            id: id,
            runKey: runKey,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            startTime: startTime,
            endTime: endTime,
            durationS: durationS,
            distanceM: distanceM,
            avgHr: avgHr,
            maxHr: maxHr,
            treadmill: treadmill,
            title: title,
            activityType: activityType,
            calories: calories,
            movingTimeS: movingTimeS,
            elapsedTimeS: elapsedTimeS,
            sourcePriority: sourcePriority,
            importFileName: importFileName,
            rawMetricsJson: rawMetricsJson,
            source: source,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> runKey = const Value.absent(),
            Value<String?> workoutDayId = const Value.absent(),
            Value<String?> planDayId = const Value.absent(),
            Value<int?> startTime = const Value.absent(),
            Value<int?> endTime = const Value.absent(),
            Value<int?> durationS = const Value.absent(),
            Value<double?> distanceM = const Value.absent(),
            Value<double?> avgHr = const Value.absent(),
            Value<double?> maxHr = const Value.absent(),
            Value<bool?> treadmill = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> activityType = const Value.absent(),
            Value<int?> calories = const Value.absent(),
            Value<int?> movingTimeS = const Value.absent(),
            Value<int?> elapsedTimeS = const Value.absent(),
            Value<int> sourcePriority = const Value.absent(),
            Value<String?> importFileName = const Value.absent(),
            Value<String?> rawMetricsJson = const Value.absent(),
            required String source,
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSessionsCompanion.insert(
            id: id,
            runKey: runKey,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            startTime: startTime,
            endTime: endTime,
            durationS: durationS,
            distanceM: distanceM,
            avgHr: avgHr,
            maxHr: maxHr,
            treadmill: treadmill,
            title: title,
            activityType: activityType,
            calories: calories,
            movingTimeS: movingTimeS,
            elapsedTimeS: elapsedTimeS,
            sourcePriority: sourcePriority,
            importFileName: importFileName,
            rawMetricsJson: rawMetricsJson,
            source: source,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $RunSessionsTable,
    RunSession,
    $$RunSessionsTableFilterComposer,
    $$RunSessionsTableOrderingComposer,
    $$RunSessionsTableAnnotationComposer,
    $$RunSessionsTableCreateCompanionBuilder,
    $$RunSessionsTableUpdateCompanionBuilder,
    (RunSession, BaseReferences<_$AppDb, $RunSessionsTable, RunSession>),
    RunSession,
    PrefetchHooks Function()>;
typedef $$RunSegmentsTableCreateCompanionBuilder = RunSegmentsCompanion
    Function({
  required String id,
  required String runSessionId,
  required int idx,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> speedMps,
  Value<int> rowid,
});
typedef $$RunSegmentsTableUpdateCompanionBuilder = RunSegmentsCompanion
    Function({
  Value<String> id,
  Value<String> runSessionId,
  Value<int> idx,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> speedMps,
  Value<int> rowid,
});

class $$RunSegmentsTableFilterComposer
    extends Composer<_$AppDb, $RunSegmentsTable> {
  $$RunSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get idx => $composableBuilder(
      column: $table.idx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationS => $composableBuilder(
      column: $table.durationS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speedMps => $composableBuilder(
      column: $table.speedMps, builder: (column) => ColumnFilters(column));
}

class $$RunSegmentsTableOrderingComposer
    extends Composer<_$AppDb, $RunSegmentsTable> {
  $$RunSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get idx => $composableBuilder(
      column: $table.idx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationS => $composableBuilder(
      column: $table.durationS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speedMps => $composableBuilder(
      column: $table.speedMps, builder: (column) => ColumnOrderings(column));
}

class $$RunSegmentsTableAnnotationComposer
    extends Composer<_$AppDb, $RunSegmentsTable> {
  $$RunSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId, builder: (column) => column);

  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);
}

class $$RunSegmentsTableTableManager extends RootTableManager<
    _$AppDb,
    $RunSegmentsTable,
    RunSegment,
    $$RunSegmentsTableFilterComposer,
    $$RunSegmentsTableOrderingComposer,
    $$RunSegmentsTableAnnotationComposer,
    $$RunSegmentsTableCreateCompanionBuilder,
    $$RunSegmentsTableUpdateCompanionBuilder,
    (RunSegment, BaseReferences<_$AppDb, $RunSegmentsTable, RunSegment>),
    RunSegment,
    PrefetchHooks Function()> {
  $$RunSegmentsTableTableManager(_$AppDb db, $RunSegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> runSessionId = const Value.absent(),
            Value<int> idx = const Value.absent(),
            Value<int?> durationS = const Value.absent(),
            Value<double?> distanceM = const Value.absent(),
            Value<double?> speedMps = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSegmentsCompanion(
            id: id,
            runSessionId: runSessionId,
            idx: idx,
            durationS: durationS,
            distanceM: distanceM,
            speedMps: speedMps,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String runSessionId,
            required int idx,
            Value<int?> durationS = const Value.absent(),
            Value<double?> distanceM = const Value.absent(),
            Value<double?> speedMps = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSegmentsCompanion.insert(
            id: id,
            runSessionId: runSessionId,
            idx: idx,
            durationS: durationS,
            distanceM: distanceM,
            speedMps: speedMps,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunSegmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $RunSegmentsTable,
    RunSegment,
    $$RunSegmentsTableFilterComposer,
    $$RunSegmentsTableOrderingComposer,
    $$RunSegmentsTableAnnotationComposer,
    $$RunSegmentsTableCreateCompanionBuilder,
    $$RunSegmentsTableUpdateCompanionBuilder,
    (RunSegment, BaseReferences<_$AppDb, $RunSegmentsTable, RunSegment>),
    RunSegment,
    PrefetchHooks Function()>;
typedef $$RunSessionDetailsTableCreateCompanionBuilder
    = RunSessionDetailsCompanion Function({
  required String runSessionId,
  Value<bool?> favorite,
  Value<double?> aerobicTe,
  Value<double?> avgRunCadence,
  Value<double?> maxRunCadence,
  Value<double?> avgPaceS,
  Value<double?> bestPaceS,
  Value<double?> totalAscent,
  Value<double?> totalDescent,
  Value<double?> avgStrideLengthM,
  Value<double?> trainingStressScore,
  Value<int?> steps,
  Value<double?> minTemp,
  Value<double?> maxTemp,
  Value<String?> decompression,
  Value<double?> bestLapTimeS,
  Value<int?> numberOfLaps,
  Value<double?> minElevation,
  Value<double?> maxElevation,
  required String rawMetricsJson,
  Value<int> rowid,
});
typedef $$RunSessionDetailsTableUpdateCompanionBuilder
    = RunSessionDetailsCompanion Function({
  Value<String> runSessionId,
  Value<bool?> favorite,
  Value<double?> aerobicTe,
  Value<double?> avgRunCadence,
  Value<double?> maxRunCadence,
  Value<double?> avgPaceS,
  Value<double?> bestPaceS,
  Value<double?> totalAscent,
  Value<double?> totalDescent,
  Value<double?> avgStrideLengthM,
  Value<double?> trainingStressScore,
  Value<int?> steps,
  Value<double?> minTemp,
  Value<double?> maxTemp,
  Value<String?> decompression,
  Value<double?> bestLapTimeS,
  Value<int?> numberOfLaps,
  Value<double?> minElevation,
  Value<double?> maxElevation,
  Value<String> rawMetricsJson,
  Value<int> rowid,
});

class $$RunSessionDetailsTableFilterComposer
    extends Composer<_$AppDb, $RunSessionDetailsTable> {
  $$RunSessionDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get favorite => $composableBuilder(
      column: $table.favorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get aerobicTe => $composableBuilder(
      column: $table.aerobicTe, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgRunCadence => $composableBuilder(
      column: $table.avgRunCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxRunCadence => $composableBuilder(
      column: $table.maxRunCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgPaceS => $composableBuilder(
      column: $table.avgPaceS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestPaceS => $composableBuilder(
      column: $table.bestPaceS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgStrideLengthM => $composableBuilder(
      column: $table.avgStrideLengthM,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get trainingStressScore => $composableBuilder(
      column: $table.trainingStressScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minTemp => $composableBuilder(
      column: $table.minTemp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxTemp => $composableBuilder(
      column: $table.maxTemp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decompression => $composableBuilder(
      column: $table.decompression, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bestLapTimeS => $composableBuilder(
      column: $table.bestLapTimeS, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfLaps => $composableBuilder(
      column: $table.numberOfLaps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minElevation => $composableBuilder(
      column: $table.minElevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxElevation => $composableBuilder(
      column: $table.maxElevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson,
      builder: (column) => ColumnFilters(column));
}

class $$RunSessionDetailsTableOrderingComposer
    extends Composer<_$AppDb, $RunSessionDetailsTable> {
  $$RunSessionDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get favorite => $composableBuilder(
      column: $table.favorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get aerobicTe => $composableBuilder(
      column: $table.aerobicTe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgRunCadence => $composableBuilder(
      column: $table.avgRunCadence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxRunCadence => $composableBuilder(
      column: $table.maxRunCadence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgPaceS => $composableBuilder(
      column: $table.avgPaceS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestPaceS => $composableBuilder(
      column: $table.bestPaceS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgStrideLengthM => $composableBuilder(
      column: $table.avgStrideLengthM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get trainingStressScore => $composableBuilder(
      column: $table.trainingStressScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minTemp => $composableBuilder(
      column: $table.minTemp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxTemp => $composableBuilder(
      column: $table.maxTemp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decompression => $composableBuilder(
      column: $table.decompression,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bestLapTimeS => $composableBuilder(
      column: $table.bestLapTimeS,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfLaps => $composableBuilder(
      column: $table.numberOfLaps,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minElevation => $composableBuilder(
      column: $table.minElevation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxElevation => $composableBuilder(
      column: $table.maxElevation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson,
      builder: (column) => ColumnOrderings(column));
}

class $$RunSessionDetailsTableAnnotationComposer
    extends Composer<_$AppDb, $RunSessionDetailsTable> {
  $$RunSessionDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get runSessionId => $composableBuilder(
      column: $table.runSessionId, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<double> get aerobicTe =>
      $composableBuilder(column: $table.aerobicTe, builder: (column) => column);

  GeneratedColumn<double> get avgRunCadence => $composableBuilder(
      column: $table.avgRunCadence, builder: (column) => column);

  GeneratedColumn<double> get maxRunCadence => $composableBuilder(
      column: $table.maxRunCadence, builder: (column) => column);

  GeneratedColumn<double> get avgPaceS =>
      $composableBuilder(column: $table.avgPaceS, builder: (column) => column);

  GeneratedColumn<double> get bestPaceS =>
      $composableBuilder(column: $table.bestPaceS, builder: (column) => column);

  GeneratedColumn<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => column);

  GeneratedColumn<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent, builder: (column) => column);

  GeneratedColumn<double> get avgStrideLengthM => $composableBuilder(
      column: $table.avgStrideLengthM, builder: (column) => column);

  GeneratedColumn<double> get trainingStressScore => $composableBuilder(
      column: $table.trainingStressScore, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get minTemp =>
      $composableBuilder(column: $table.minTemp, builder: (column) => column);

  GeneratedColumn<double> get maxTemp =>
      $composableBuilder(column: $table.maxTemp, builder: (column) => column);

  GeneratedColumn<String> get decompression => $composableBuilder(
      column: $table.decompression, builder: (column) => column);

  GeneratedColumn<double> get bestLapTimeS => $composableBuilder(
      column: $table.bestLapTimeS, builder: (column) => column);

  GeneratedColumn<int> get numberOfLaps => $composableBuilder(
      column: $table.numberOfLaps, builder: (column) => column);

  GeneratedColumn<double> get minElevation => $composableBuilder(
      column: $table.minElevation, builder: (column) => column);

  GeneratedColumn<double> get maxElevation => $composableBuilder(
      column: $table.maxElevation, builder: (column) => column);

  GeneratedColumn<String> get rawMetricsJson => $composableBuilder(
      column: $table.rawMetricsJson, builder: (column) => column);
}

class $$RunSessionDetailsTableTableManager extends RootTableManager<
    _$AppDb,
    $RunSessionDetailsTable,
    RunSessionDetail,
    $$RunSessionDetailsTableFilterComposer,
    $$RunSessionDetailsTableOrderingComposer,
    $$RunSessionDetailsTableAnnotationComposer,
    $$RunSessionDetailsTableCreateCompanionBuilder,
    $$RunSessionDetailsTableUpdateCompanionBuilder,
    (
      RunSessionDetail,
      BaseReferences<_$AppDb, $RunSessionDetailsTable, RunSessionDetail>
    ),
    RunSessionDetail,
    PrefetchHooks Function()> {
  $$RunSessionDetailsTableTableManager(
      _$AppDb db, $RunSessionDetailsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunSessionDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunSessionDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunSessionDetailsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> runSessionId = const Value.absent(),
            Value<bool?> favorite = const Value.absent(),
            Value<double?> aerobicTe = const Value.absent(),
            Value<double?> avgRunCadence = const Value.absent(),
            Value<double?> maxRunCadence = const Value.absent(),
            Value<double?> avgPaceS = const Value.absent(),
            Value<double?> bestPaceS = const Value.absent(),
            Value<double?> totalAscent = const Value.absent(),
            Value<double?> totalDescent = const Value.absent(),
            Value<double?> avgStrideLengthM = const Value.absent(),
            Value<double?> trainingStressScore = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            Value<double?> minTemp = const Value.absent(),
            Value<double?> maxTemp = const Value.absent(),
            Value<String?> decompression = const Value.absent(),
            Value<double?> bestLapTimeS = const Value.absent(),
            Value<int?> numberOfLaps = const Value.absent(),
            Value<double?> minElevation = const Value.absent(),
            Value<double?> maxElevation = const Value.absent(),
            Value<String> rawMetricsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSessionDetailsCompanion(
            runSessionId: runSessionId,
            favorite: favorite,
            aerobicTe: aerobicTe,
            avgRunCadence: avgRunCadence,
            maxRunCadence: maxRunCadence,
            avgPaceS: avgPaceS,
            bestPaceS: bestPaceS,
            totalAscent: totalAscent,
            totalDescent: totalDescent,
            avgStrideLengthM: avgStrideLengthM,
            trainingStressScore: trainingStressScore,
            steps: steps,
            minTemp: minTemp,
            maxTemp: maxTemp,
            decompression: decompression,
            bestLapTimeS: bestLapTimeS,
            numberOfLaps: numberOfLaps,
            minElevation: minElevation,
            maxElevation: maxElevation,
            rawMetricsJson: rawMetricsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String runSessionId,
            Value<bool?> favorite = const Value.absent(),
            Value<double?> aerobicTe = const Value.absent(),
            Value<double?> avgRunCadence = const Value.absent(),
            Value<double?> maxRunCadence = const Value.absent(),
            Value<double?> avgPaceS = const Value.absent(),
            Value<double?> bestPaceS = const Value.absent(),
            Value<double?> totalAscent = const Value.absent(),
            Value<double?> totalDescent = const Value.absent(),
            Value<double?> avgStrideLengthM = const Value.absent(),
            Value<double?> trainingStressScore = const Value.absent(),
            Value<int?> steps = const Value.absent(),
            Value<double?> minTemp = const Value.absent(),
            Value<double?> maxTemp = const Value.absent(),
            Value<String?> decompression = const Value.absent(),
            Value<double?> bestLapTimeS = const Value.absent(),
            Value<int?> numberOfLaps = const Value.absent(),
            Value<double?> minElevation = const Value.absent(),
            Value<double?> maxElevation = const Value.absent(),
            required String rawMetricsJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              RunSessionDetailsCompanion.insert(
            runSessionId: runSessionId,
            favorite: favorite,
            aerobicTe: aerobicTe,
            avgRunCadence: avgRunCadence,
            maxRunCadence: maxRunCadence,
            avgPaceS: avgPaceS,
            bestPaceS: bestPaceS,
            totalAscent: totalAscent,
            totalDescent: totalDescent,
            avgStrideLengthM: avgStrideLengthM,
            trainingStressScore: trainingStressScore,
            steps: steps,
            minTemp: minTemp,
            maxTemp: maxTemp,
            decompression: decompression,
            bestLapTimeS: bestLapTimeS,
            numberOfLaps: numberOfLaps,
            minElevation: minElevation,
            maxElevation: maxElevation,
            rawMetricsJson: rawMetricsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunSessionDetailsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $RunSessionDetailsTable,
    RunSessionDetail,
    $$RunSessionDetailsTableFilterComposer,
    $$RunSessionDetailsTableOrderingComposer,
    $$RunSessionDetailsTableAnnotationComposer,
    $$RunSessionDetailsTableCreateCompanionBuilder,
    $$RunSessionDetailsTableUpdateCompanionBuilder,
    (
      RunSessionDetail,
      BaseReferences<_$AppDb, $RunSessionDetailsTable, RunSessionDetail>
    ),
    RunSessionDetail,
    PrefetchHooks Function()>;
typedef $$RunOverrideAuditTableCreateCompanionBuilder
    = RunOverrideAuditCompanion Function({
  required String id,
  required String runKey,
  Value<String?> workoutDayId,
  required String oldSource,
  required String newSource,
  required String oldSnapshotJson,
  required String newSnapshotJson,
  required String reason,
  required int createdAt,
  Value<int> rowid,
});
typedef $$RunOverrideAuditTableUpdateCompanionBuilder
    = RunOverrideAuditCompanion Function({
  Value<String> id,
  Value<String> runKey,
  Value<String?> workoutDayId,
  Value<String> oldSource,
  Value<String> newSource,
  Value<String> oldSnapshotJson,
  Value<String> newSnapshotJson,
  Value<String> reason,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$RunOverrideAuditTableFilterComposer
    extends Composer<_$AppDb, $RunOverrideAuditTable> {
  $$RunOverrideAuditTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runKey => $composableBuilder(
      column: $table.runKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldSource => $composableBuilder(
      column: $table.oldSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newSource => $composableBuilder(
      column: $table.newSource, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldSnapshotJson => $composableBuilder(
      column: $table.oldSnapshotJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newSnapshotJson => $composableBuilder(
      column: $table.newSnapshotJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RunOverrideAuditTableOrderingComposer
    extends Composer<_$AppDb, $RunOverrideAuditTable> {
  $$RunOverrideAuditTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runKey => $composableBuilder(
      column: $table.runKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldSource => $composableBuilder(
      column: $table.oldSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newSource => $composableBuilder(
      column: $table.newSource, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldSnapshotJson => $composableBuilder(
      column: $table.oldSnapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newSnapshotJson => $composableBuilder(
      column: $table.newSnapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RunOverrideAuditTableAnnotationComposer
    extends Composer<_$AppDb, $RunOverrideAuditTable> {
  $$RunOverrideAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runKey =>
      $composableBuilder(column: $table.runKey, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => column);

  GeneratedColumn<String> get oldSource =>
      $composableBuilder(column: $table.oldSource, builder: (column) => column);

  GeneratedColumn<String> get newSource =>
      $composableBuilder(column: $table.newSource, builder: (column) => column);

  GeneratedColumn<String> get oldSnapshotJson => $composableBuilder(
      column: $table.oldSnapshotJson, builder: (column) => column);

  GeneratedColumn<String> get newSnapshotJson => $composableBuilder(
      column: $table.newSnapshotJson, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RunOverrideAuditTableTableManager extends RootTableManager<
    _$AppDb,
    $RunOverrideAuditTable,
    RunOverrideAuditData,
    $$RunOverrideAuditTableFilterComposer,
    $$RunOverrideAuditTableOrderingComposer,
    $$RunOverrideAuditTableAnnotationComposer,
    $$RunOverrideAuditTableCreateCompanionBuilder,
    $$RunOverrideAuditTableUpdateCompanionBuilder,
    (
      RunOverrideAuditData,
      BaseReferences<_$AppDb, $RunOverrideAuditTable, RunOverrideAuditData>
    ),
    RunOverrideAuditData,
    PrefetchHooks Function()> {
  $$RunOverrideAuditTableTableManager(_$AppDb db, $RunOverrideAuditTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunOverrideAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunOverrideAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunOverrideAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> runKey = const Value.absent(),
            Value<String?> workoutDayId = const Value.absent(),
            Value<String> oldSource = const Value.absent(),
            Value<String> newSource = const Value.absent(),
            Value<String> oldSnapshotJson = const Value.absent(),
            Value<String> newSnapshotJson = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RunOverrideAuditCompanion(
            id: id,
            runKey: runKey,
            workoutDayId: workoutDayId,
            oldSource: oldSource,
            newSource: newSource,
            oldSnapshotJson: oldSnapshotJson,
            newSnapshotJson: newSnapshotJson,
            reason: reason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String runKey,
            Value<String?> workoutDayId = const Value.absent(),
            required String oldSource,
            required String newSource,
            required String oldSnapshotJson,
            required String newSnapshotJson,
            required String reason,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RunOverrideAuditCompanion.insert(
            id: id,
            runKey: runKey,
            workoutDayId: workoutDayId,
            oldSource: oldSource,
            newSource: newSource,
            oldSnapshotJson: oldSnapshotJson,
            newSnapshotJson: newSnapshotJson,
            reason: reason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RunOverrideAuditTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $RunOverrideAuditTable,
    RunOverrideAuditData,
    $$RunOverrideAuditTableFilterComposer,
    $$RunOverrideAuditTableOrderingComposer,
    $$RunOverrideAuditTableAnnotationComposer,
    $$RunOverrideAuditTableCreateCompanionBuilder,
    $$RunOverrideAuditTableUpdateCompanionBuilder,
    (
      RunOverrideAuditData,
      BaseReferences<_$AppDb, $RunOverrideAuditTable, RunOverrideAuditData>
    ),
    RunOverrideAuditData,
    PrefetchHooks Function()>;
typedef $$RuleTriggersTableCreateCompanionBuilder = RuleTriggersCompanion
    Function({
  required String id,
  required String triggerDate,
  required String ruleCode,
  required bool triggered,
  required String detailsJson,
  required int createdAt,
  Value<int> rowid,
});
typedef $$RuleTriggersTableUpdateCompanionBuilder = RuleTriggersCompanion
    Function({
  Value<String> id,
  Value<String> triggerDate,
  Value<String> ruleCode,
  Value<bool> triggered,
  Value<String> detailsJson,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$RuleTriggersTableFilterComposer
    extends Composer<_$AppDb, $RuleTriggersTable> {
  $$RuleTriggersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get triggerDate => $composableBuilder(
      column: $table.triggerDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruleCode => $composableBuilder(
      column: $table.ruleCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get triggered => $composableBuilder(
      column: $table.triggered, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RuleTriggersTableOrderingComposer
    extends Composer<_$AppDb, $RuleTriggersTable> {
  $$RuleTriggersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get triggerDate => $composableBuilder(
      column: $table.triggerDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruleCode => $composableBuilder(
      column: $table.ruleCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get triggered => $composableBuilder(
      column: $table.triggered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RuleTriggersTableAnnotationComposer
    extends Composer<_$AppDb, $RuleTriggersTable> {
  $$RuleTriggersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get triggerDate => $composableBuilder(
      column: $table.triggerDate, builder: (column) => column);

  GeneratedColumn<String> get ruleCode =>
      $composableBuilder(column: $table.ruleCode, builder: (column) => column);

  GeneratedColumn<bool> get triggered =>
      $composableBuilder(column: $table.triggered, builder: (column) => column);

  GeneratedColumn<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RuleTriggersTableTableManager extends RootTableManager<
    _$AppDb,
    $RuleTriggersTable,
    RuleTrigger,
    $$RuleTriggersTableFilterComposer,
    $$RuleTriggersTableOrderingComposer,
    $$RuleTriggersTableAnnotationComposer,
    $$RuleTriggersTableCreateCompanionBuilder,
    $$RuleTriggersTableUpdateCompanionBuilder,
    (RuleTrigger, BaseReferences<_$AppDb, $RuleTriggersTable, RuleTrigger>),
    RuleTrigger,
    PrefetchHooks Function()> {
  $$RuleTriggersTableTableManager(_$AppDb db, $RuleTriggersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleTriggersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleTriggersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleTriggersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> triggerDate = const Value.absent(),
            Value<String> ruleCode = const Value.absent(),
            Value<bool> triggered = const Value.absent(),
            Value<String> detailsJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RuleTriggersCompanion(
            id: id,
            triggerDate: triggerDate,
            ruleCode: ruleCode,
            triggered: triggered,
            detailsJson: detailsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String triggerDate,
            required String ruleCode,
            required bool triggered,
            required String detailsJson,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RuleTriggersCompanion.insert(
            id: id,
            triggerDate: triggerDate,
            ruleCode: ruleCode,
            triggered: triggered,
            detailsJson: detailsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RuleTriggersTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $RuleTriggersTable,
    RuleTrigger,
    $$RuleTriggersTableFilterComposer,
    $$RuleTriggersTableOrderingComposer,
    $$RuleTriggersTableAnnotationComposer,
    $$RuleTriggersTableCreateCompanionBuilder,
    $$RuleTriggersTableUpdateCompanionBuilder,
    (RuleTrigger, BaseReferences<_$AppDb, $RuleTriggersTable, RuleTrigger>),
    RuleTrigger,
    PrefetchHooks Function()>;
typedef $$AiAuditTableCreateCompanionBuilder = AiAuditCompanion Function({
  required String id,
  required int requestedAt,
  Value<String?> dateWindowStart,
  Value<String?> dateWindowEnd,
  required String inputSnapshotJson,
  required String responseJson,
  required bool schemaValid,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$AiAuditTableUpdateCompanionBuilder = AiAuditCompanion Function({
  Value<String> id,
  Value<int> requestedAt,
  Value<String?> dateWindowStart,
  Value<String?> dateWindowEnd,
  Value<String> inputSnapshotJson,
  Value<String> responseJson,
  Value<bool> schemaValid,
  Value<String?> notes,
  Value<int> rowid,
});

class $$AiAuditTableFilterComposer extends Composer<_$AppDb, $AiAuditTable> {
  $$AiAuditTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requestedAt => $composableBuilder(
      column: $table.requestedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateWindowStart => $composableBuilder(
      column: $table.dateWindowStart,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateWindowEnd => $composableBuilder(
      column: $table.dateWindowEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inputSnapshotJson => $composableBuilder(
      column: $table.inputSnapshotJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get schemaValid => $composableBuilder(
      column: $table.schemaValid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$AiAuditTableOrderingComposer extends Composer<_$AppDb, $AiAuditTable> {
  $$AiAuditTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requestedAt => $composableBuilder(
      column: $table.requestedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateWindowStart => $composableBuilder(
      column: $table.dateWindowStart,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateWindowEnd => $composableBuilder(
      column: $table.dateWindowEnd,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inputSnapshotJson => $composableBuilder(
      column: $table.inputSnapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseJson => $composableBuilder(
      column: $table.responseJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get schemaValid => $composableBuilder(
      column: $table.schemaValid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$AiAuditTableAnnotationComposer
    extends Composer<_$AppDb, $AiAuditTable> {
  $$AiAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get requestedAt => $composableBuilder(
      column: $table.requestedAt, builder: (column) => column);

  GeneratedColumn<String> get dateWindowStart => $composableBuilder(
      column: $table.dateWindowStart, builder: (column) => column);

  GeneratedColumn<String> get dateWindowEnd => $composableBuilder(
      column: $table.dateWindowEnd, builder: (column) => column);

  GeneratedColumn<String> get inputSnapshotJson => $composableBuilder(
      column: $table.inputSnapshotJson, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
      column: $table.responseJson, builder: (column) => column);

  GeneratedColumn<bool> get schemaValid => $composableBuilder(
      column: $table.schemaValid, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$AiAuditTableTableManager extends RootTableManager<
    _$AppDb,
    $AiAuditTable,
    AiAuditData,
    $$AiAuditTableFilterComposer,
    $$AiAuditTableOrderingComposer,
    $$AiAuditTableAnnotationComposer,
    $$AiAuditTableCreateCompanionBuilder,
    $$AiAuditTableUpdateCompanionBuilder,
    (AiAuditData, BaseReferences<_$AppDb, $AiAuditTable, AiAuditData>),
    AiAuditData,
    PrefetchHooks Function()> {
  $$AiAuditTableTableManager(_$AppDb db, $AiAuditTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> requestedAt = const Value.absent(),
            Value<String?> dateWindowStart = const Value.absent(),
            Value<String?> dateWindowEnd = const Value.absent(),
            Value<String> inputSnapshotJson = const Value.absent(),
            Value<String> responseJson = const Value.absent(),
            Value<bool> schemaValid = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiAuditCompanion(
            id: id,
            requestedAt: requestedAt,
            dateWindowStart: dateWindowStart,
            dateWindowEnd: dateWindowEnd,
            inputSnapshotJson: inputSnapshotJson,
            responseJson: responseJson,
            schemaValid: schemaValid,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int requestedAt,
            Value<String?> dateWindowStart = const Value.absent(),
            Value<String?> dateWindowEnd = const Value.absent(),
            required String inputSnapshotJson,
            required String responseJson,
            required bool schemaValid,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiAuditCompanion.insert(
            id: id,
            requestedAt: requestedAt,
            dateWindowStart: dateWindowStart,
            dateWindowEnd: dateWindowEnd,
            inputSnapshotJson: inputSnapshotJson,
            responseJson: responseJson,
            schemaValid: schemaValid,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiAuditTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $AiAuditTable,
    AiAuditData,
    $$AiAuditTableFilterComposer,
    $$AiAuditTableOrderingComposer,
    $$AiAuditTableAnnotationComposer,
    $$AiAuditTableCreateCompanionBuilder,
    $$AiAuditTableUpdateCompanionBuilder,
    (AiAuditData, BaseReferences<_$AppDb, $AiAuditTable, AiAuditData>),
    AiAuditData,
    PrefetchHooks Function()>;
typedef $$ExerciseSubstitutionsTableCreateCompanionBuilder
    = ExerciseSubstitutionsCompanion Function({
  required String id,
  required String workoutDayId,
  Value<String?> planDayId,
  required String prescribedExerciseCanonical,
  required String substituteExerciseCanonical,
  required String reasonCode,
  Value<String?> reasonNotes,
  required int selectedAt,
  Value<String?> selectedBy,
  Value<double?> matchScore,
  Value<String?> matchExplanationJson,
  Value<bool> warningAcknowledged,
  required int createdAt,
  Value<int> rowid,
});
typedef $$ExerciseSubstitutionsTableUpdateCompanionBuilder
    = ExerciseSubstitutionsCompanion Function({
  Value<String> id,
  Value<String> workoutDayId,
  Value<String?> planDayId,
  Value<String> prescribedExerciseCanonical,
  Value<String> substituteExerciseCanonical,
  Value<String> reasonCode,
  Value<String?> reasonNotes,
  Value<int> selectedAt,
  Value<String?> selectedBy,
  Value<double?> matchScore,
  Value<String?> matchExplanationJson,
  Value<bool> warningAcknowledged,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$ExerciseSubstitutionsTableFilterComposer
    extends Composer<_$AppDb, $ExerciseSubstitutionsTable> {
  $$ExerciseSubstitutionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get substituteExerciseCanonical => $composableBuilder(
      column: $table.substituteExerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonNotes => $composableBuilder(
      column: $table.reasonNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get selectedAt => $composableBuilder(
      column: $table.selectedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedBy => $composableBuilder(
      column: $table.selectedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchExplanationJson => $composableBuilder(
      column: $table.matchExplanationJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get warningAcknowledged => $composableBuilder(
      column: $table.warningAcknowledged,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ExerciseSubstitutionsTableOrderingComposer
    extends Composer<_$AppDb, $ExerciseSubstitutionsTable> {
  $$ExerciseSubstitutionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get substituteExerciseCanonical => $composableBuilder(
      column: $table.substituteExerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonNotes => $composableBuilder(
      column: $table.reasonNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get selectedAt => $composableBuilder(
      column: $table.selectedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedBy => $composableBuilder(
      column: $table.selectedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchExplanationJson => $composableBuilder(
      column: $table.matchExplanationJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get warningAcknowledged => $composableBuilder(
      column: $table.warningAcknowledged,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExerciseSubstitutionsTableAnnotationComposer
    extends Composer<_$AppDb, $ExerciseSubstitutionsTable> {
  $$ExerciseSubstitutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
      column: $table.workoutDayId, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical, builder: (column) => column);

  GeneratedColumn<String> get substituteExerciseCanonical => $composableBuilder(
      column: $table.substituteExerciseCanonical, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => column);

  GeneratedColumn<String> get reasonNotes => $composableBuilder(
      column: $table.reasonNotes, builder: (column) => column);

  GeneratedColumn<int> get selectedAt => $composableBuilder(
      column: $table.selectedAt, builder: (column) => column);

  GeneratedColumn<String> get selectedBy => $composableBuilder(
      column: $table.selectedBy, builder: (column) => column);

  GeneratedColumn<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => column);

  GeneratedColumn<String> get matchExplanationJson => $composableBuilder(
      column: $table.matchExplanationJson, builder: (column) => column);

  GeneratedColumn<bool> get warningAcknowledged => $composableBuilder(
      column: $table.warningAcknowledged, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExerciseSubstitutionsTableTableManager extends RootTableManager<
    _$AppDb,
    $ExerciseSubstitutionsTable,
    ExerciseSubstitution,
    $$ExerciseSubstitutionsTableFilterComposer,
    $$ExerciseSubstitutionsTableOrderingComposer,
    $$ExerciseSubstitutionsTableAnnotationComposer,
    $$ExerciseSubstitutionsTableCreateCompanionBuilder,
    $$ExerciseSubstitutionsTableUpdateCompanionBuilder,
    (
      ExerciseSubstitution,
      BaseReferences<_$AppDb, $ExerciseSubstitutionsTable, ExerciseSubstitution>
    ),
    ExerciseSubstitution,
    PrefetchHooks Function()> {
  $$ExerciseSubstitutionsTableTableManager(
      _$AppDb db, $ExerciseSubstitutionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseSubstitutionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseSubstitutionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseSubstitutionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workoutDayId = const Value.absent(),
            Value<String?> planDayId = const Value.absent(),
            Value<String> prescribedExerciseCanonical = const Value.absent(),
            Value<String> substituteExerciseCanonical = const Value.absent(),
            Value<String> reasonCode = const Value.absent(),
            Value<String?> reasonNotes = const Value.absent(),
            Value<int> selectedAt = const Value.absent(),
            Value<String?> selectedBy = const Value.absent(),
            Value<double?> matchScore = const Value.absent(),
            Value<String?> matchExplanationJson = const Value.absent(),
            Value<bool> warningAcknowledged = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseSubstitutionsCompanion(
            id: id,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            substituteExerciseCanonical: substituteExerciseCanonical,
            reasonCode: reasonCode,
            reasonNotes: reasonNotes,
            selectedAt: selectedAt,
            selectedBy: selectedBy,
            matchScore: matchScore,
            matchExplanationJson: matchExplanationJson,
            warningAcknowledged: warningAcknowledged,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workoutDayId,
            Value<String?> planDayId = const Value.absent(),
            required String prescribedExerciseCanonical,
            required String substituteExerciseCanonical,
            required String reasonCode,
            Value<String?> reasonNotes = const Value.absent(),
            required int selectedAt,
            Value<String?> selectedBy = const Value.absent(),
            Value<double?> matchScore = const Value.absent(),
            Value<String?> matchExplanationJson = const Value.absent(),
            Value<bool> warningAcknowledged = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExerciseSubstitutionsCompanion.insert(
            id: id,
            workoutDayId: workoutDayId,
            planDayId: planDayId,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            substituteExerciseCanonical: substituteExerciseCanonical,
            reasonCode: reasonCode,
            reasonNotes: reasonNotes,
            selectedAt: selectedAt,
            selectedBy: selectedBy,
            matchScore: matchScore,
            matchExplanationJson: matchExplanationJson,
            warningAcknowledged: warningAcknowledged,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExerciseSubstitutionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $ExerciseSubstitutionsTable,
        ExerciseSubstitution,
        $$ExerciseSubstitutionsTableFilterComposer,
        $$ExerciseSubstitutionsTableOrderingComposer,
        $$ExerciseSubstitutionsTableAnnotationComposer,
        $$ExerciseSubstitutionsTableCreateCompanionBuilder,
        $$ExerciseSubstitutionsTableUpdateCompanionBuilder,
        (
          ExerciseSubstitution,
          BaseReferences<_$AppDb, $ExerciseSubstitutionsTable,
              ExerciseSubstitution>
        ),
        ExerciseSubstitution,
        PrefetchHooks Function()>;
typedef $$PlanCyclesTableCreateCompanionBuilder = PlanCyclesCompanion Function({
  required String id,
  required String cycleKey,
  required String weekStart,
  required String weekEnd,
  required String source,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanCyclesTableUpdateCompanionBuilder = PlanCyclesCompanion Function({
  Value<String> id,
  Value<String> cycleKey,
  Value<String> weekStart,
  Value<String> weekEnd,
  Value<String> source,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanCyclesTableFilterComposer
    extends Composer<_$AppDb, $PlanCyclesTable> {
  $$PlanCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cycleKey => $composableBuilder(
      column: $table.cycleKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanCyclesTableOrderingComposer
    extends Composer<_$AppDb, $PlanCyclesTable> {
  $$PlanCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycleKey => $composableBuilder(
      column: $table.cycleKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanCyclesTableAnnotationComposer
    extends Composer<_$AppDb, $PlanCyclesTable> {
  $$PlanCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cycleKey =>
      $composableBuilder(column: $table.cycleKey, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get weekEnd =>
      $composableBuilder(column: $table.weekEnd, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanCyclesTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanCyclesTable,
    PlanCycle,
    $$PlanCyclesTableFilterComposer,
    $$PlanCyclesTableOrderingComposer,
    $$PlanCyclesTableAnnotationComposer,
    $$PlanCyclesTableCreateCompanionBuilder,
    $$PlanCyclesTableUpdateCompanionBuilder,
    (PlanCycle, BaseReferences<_$AppDb, $PlanCyclesTable, PlanCycle>),
    PlanCycle,
    PrefetchHooks Function()> {
  $$PlanCyclesTableTableManager(_$AppDb db, $PlanCyclesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> cycleKey = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<String> weekEnd = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanCyclesCompanion(
            id: id,
            cycleKey: cycleKey,
            weekStart: weekStart,
            weekEnd: weekEnd,
            source: source,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String cycleKey,
            required String weekStart,
            required String weekEnd,
            required String source,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanCyclesCompanion.insert(
            id: id,
            cycleKey: cycleKey,
            weekStart: weekStart,
            weekEnd: weekEnd,
            source: source,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanCyclesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PlanCyclesTable,
    PlanCycle,
    $$PlanCyclesTableFilterComposer,
    $$PlanCyclesTableOrderingComposer,
    $$PlanCyclesTableAnnotationComposer,
    $$PlanCyclesTableCreateCompanionBuilder,
    $$PlanCyclesTableUpdateCompanionBuilder,
    (PlanCycle, BaseReferences<_$AppDb, $PlanCyclesTable, PlanCycle>),
    PlanCycle,
    PrefetchHooks Function()>;
typedef $$PlanDaysTableCreateCompanionBuilder = PlanDaysCompanion Function({
  required String id,
  required String planCycleId,
  required int dayNumber,
  required String sheetName,
  Value<String?> estimatedDate,
  Value<String?> sessionType,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanDaysTableUpdateCompanionBuilder = PlanDaysCompanion Function({
  Value<String> id,
  Value<String> planCycleId,
  Value<int> dayNumber,
  Value<String> sheetName,
  Value<String?> estimatedDate,
  Value<String?> sessionType,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanDaysTableFilterComposer extends Composer<_$AppDb, $PlanDaysTable> {
  $$PlanDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sheetName => $composableBuilder(
      column: $table.sheetName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estimatedDate => $composableBuilder(
      column: $table.estimatedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanDaysTableOrderingComposer
    extends Composer<_$AppDb, $PlanDaysTable> {
  $$PlanDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayNumber => $composableBuilder(
      column: $table.dayNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sheetName => $composableBuilder(
      column: $table.sheetName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estimatedDate => $composableBuilder(
      column: $table.estimatedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanDaysTableAnnotationComposer
    extends Composer<_$AppDb, $PlanDaysTable> {
  $$PlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get sheetName =>
      $composableBuilder(column: $table.sheetName, builder: (column) => column);

  GeneratedColumn<String> get estimatedDate => $composableBuilder(
      column: $table.estimatedDate, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanDaysTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanDaysTable,
    PlanDay,
    $$PlanDaysTableFilterComposer,
    $$PlanDaysTableOrderingComposer,
    $$PlanDaysTableAnnotationComposer,
    $$PlanDaysTableCreateCompanionBuilder,
    $$PlanDaysTableUpdateCompanionBuilder,
    (PlanDay, BaseReferences<_$AppDb, $PlanDaysTable, PlanDay>),
    PlanDay,
    PrefetchHooks Function()> {
  $$PlanDaysTableTableManager(_$AppDb db, $PlanDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planCycleId = const Value.absent(),
            Value<int> dayNumber = const Value.absent(),
            Value<String> sheetName = const Value.absent(),
            Value<String?> estimatedDate = const Value.absent(),
            Value<String?> sessionType = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanDaysCompanion(
            id: id,
            planCycleId: planCycleId,
            dayNumber: dayNumber,
            sheetName: sheetName,
            estimatedDate: estimatedDate,
            sessionType: sessionType,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planCycleId,
            required int dayNumber,
            required String sheetName,
            Value<String?> estimatedDate = const Value.absent(),
            Value<String?> sessionType = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanDaysCompanion.insert(
            id: id,
            planCycleId: planCycleId,
            dayNumber: dayNumber,
            sheetName: sheetName,
            estimatedDate: estimatedDate,
            sessionType: sessionType,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PlanDaysTable,
    PlanDay,
    $$PlanDaysTableFilterComposer,
    $$PlanDaysTableOrderingComposer,
    $$PlanDaysTableAnnotationComposer,
    $$PlanDaysTableCreateCompanionBuilder,
    $$PlanDaysTableUpdateCompanionBuilder,
    (PlanDay, BaseReferences<_$AppDb, $PlanDaysTable, PlanDay>),
    PlanDay,
    PrefetchHooks Function()>;
typedef $$PlanExerciseAlternativesTableCreateCompanionBuilder
    = PlanExerciseAlternativesCompanion Function({
  required String id,
  Value<String?> planDayId,
  required String prescribedExerciseCanonical,
  required String alternativeExerciseCanonical,
  Value<int> priority,
  Value<String?> notes,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanExerciseAlternativesTableUpdateCompanionBuilder
    = PlanExerciseAlternativesCompanion Function({
  Value<String> id,
  Value<String?> planDayId,
  Value<String> prescribedExerciseCanonical,
  Value<String> alternativeExerciseCanonical,
  Value<int> priority,
  Value<String?> notes,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanExerciseAlternativesTableFilterComposer
    extends Composer<_$AppDb, $PlanExerciseAlternativesTable> {
  $$PlanExerciseAlternativesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alternativeExerciseCanonical => $composableBuilder(
      column: $table.alternativeExerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanExerciseAlternativesTableOrderingComposer
    extends Composer<_$AppDb, $PlanExerciseAlternativesTable> {
  $$PlanExerciseAlternativesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alternativeExerciseCanonical =>
      $composableBuilder(
          column: $table.alternativeExerciseCanonical,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanExerciseAlternativesTableAnnotationComposer
    extends Composer<_$AppDb, $PlanExerciseAlternativesTable> {
  $$PlanExerciseAlternativesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<String> get prescribedExerciseCanonical => $composableBuilder(
      column: $table.prescribedExerciseCanonical, builder: (column) => column);

  GeneratedColumn<String> get alternativeExerciseCanonical =>
      $composableBuilder(
          column: $table.alternativeExerciseCanonical,
          builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanExerciseAlternativesTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanExerciseAlternativesTable,
    PlanExerciseAlternative,
    $$PlanExerciseAlternativesTableFilterComposer,
    $$PlanExerciseAlternativesTableOrderingComposer,
    $$PlanExerciseAlternativesTableAnnotationComposer,
    $$PlanExerciseAlternativesTableCreateCompanionBuilder,
    $$PlanExerciseAlternativesTableUpdateCompanionBuilder,
    (
      PlanExerciseAlternative,
      BaseReferences<_$AppDb, $PlanExerciseAlternativesTable,
          PlanExerciseAlternative>
    ),
    PlanExerciseAlternative,
    PrefetchHooks Function()> {
  $$PlanExerciseAlternativesTableTableManager(
      _$AppDb db, $PlanExerciseAlternativesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanExerciseAlternativesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanExerciseAlternativesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanExerciseAlternativesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> planDayId = const Value.absent(),
            Value<String> prescribedExerciseCanonical = const Value.absent(),
            Value<String> alternativeExerciseCanonical = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanExerciseAlternativesCompanion(
            id: id,
            planDayId: planDayId,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            alternativeExerciseCanonical: alternativeExerciseCanonical,
            priority: priority,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> planDayId = const Value.absent(),
            required String prescribedExerciseCanonical,
            required String alternativeExerciseCanonical,
            Value<int> priority = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanExerciseAlternativesCompanion.insert(
            id: id,
            planDayId: planDayId,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            alternativeExerciseCanonical: alternativeExerciseCanonical,
            priority: priority,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanExerciseAlternativesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $PlanExerciseAlternativesTable,
        PlanExerciseAlternative,
        $$PlanExerciseAlternativesTableFilterComposer,
        $$PlanExerciseAlternativesTableOrderingComposer,
        $$PlanExerciseAlternativesTableAnnotationComposer,
        $$PlanExerciseAlternativesTableCreateCompanionBuilder,
        $$PlanExerciseAlternativesTableUpdateCompanionBuilder,
        (
          PlanExerciseAlternative,
          BaseReferences<_$AppDb, $PlanExerciseAlternativesTable,
              PlanExerciseAlternative>
        ),
        PlanExerciseAlternative,
        PrefetchHooks Function()>;
typedef $$PlanPrescribedStrengthSetsTableCreateCompanionBuilder
    = PlanPrescribedStrengthSetsCompanion Function({
  required String id,
  required String planDayId,
  required String exerciseCanonical,
  required int setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  required String unit,
  Value<String?> rawSetString,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanPrescribedStrengthSetsTableUpdateCompanionBuilder
    = PlanPrescribedStrengthSetsCompanion Function({
  Value<String> id,
  Value<String> planDayId,
  Value<String> exerciseCanonical,
  Value<int> setIndex,
  Value<double?> weight,
  Value<int?> reps,
  Value<int?> rir,
  Value<String> unit,
  Value<String?> rawSetString,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanPrescribedStrengthSetsTableFilterComposer
    extends Composer<_$AppDb, $PlanPrescribedStrengthSetsTable> {
  $$PlanPrescribedStrengthSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanPrescribedStrengthSetsTableOrderingComposer
    extends Composer<_$AppDb, $PlanPrescribedStrengthSetsTable> {
  $$PlanPrescribedStrengthSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setIndex => $composableBuilder(
      column: $table.setIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rir => $composableBuilder(
      column: $table.rir, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanPrescribedStrengthSetsTableAnnotationComposer
    extends Composer<_$AppDb, $PlanPrescribedStrengthSetsTable> {
  $$PlanPrescribedStrengthSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<String> get exerciseCanonical => $composableBuilder(
      column: $table.exerciseCanonical, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get rawSetString => $composableBuilder(
      column: $table.rawSetString, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanPrescribedStrengthSetsTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanPrescribedStrengthSetsTable,
    PlanPrescribedStrengthSet,
    $$PlanPrescribedStrengthSetsTableFilterComposer,
    $$PlanPrescribedStrengthSetsTableOrderingComposer,
    $$PlanPrescribedStrengthSetsTableAnnotationComposer,
    $$PlanPrescribedStrengthSetsTableCreateCompanionBuilder,
    $$PlanPrescribedStrengthSetsTableUpdateCompanionBuilder,
    (
      PlanPrescribedStrengthSet,
      BaseReferences<_$AppDb, $PlanPrescribedStrengthSetsTable,
          PlanPrescribedStrengthSet>
    ),
    PlanPrescribedStrengthSet,
    PrefetchHooks Function()> {
  $$PlanPrescribedStrengthSetsTableTableManager(
      _$AppDb db, $PlanPrescribedStrengthSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanPrescribedStrengthSetsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanPrescribedStrengthSetsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanPrescribedStrengthSetsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planDayId = const Value.absent(),
            Value<String> exerciseCanonical = const Value.absent(),
            Value<int> setIndex = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String?> rawSetString = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanPrescribedStrengthSetsCompanion(
            id: id,
            planDayId: planDayId,
            exerciseCanonical: exerciseCanonical,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            rawSetString: rawSetString,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planDayId,
            required String exerciseCanonical,
            required int setIndex,
            Value<double?> weight = const Value.absent(),
            Value<int?> reps = const Value.absent(),
            Value<int?> rir = const Value.absent(),
            required String unit,
            Value<String?> rawSetString = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanPrescribedStrengthSetsCompanion.insert(
            id: id,
            planDayId: planDayId,
            exerciseCanonical: exerciseCanonical,
            setIndex: setIndex,
            weight: weight,
            reps: reps,
            rir: rir,
            unit: unit,
            rawSetString: rawSetString,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanPrescribedStrengthSetsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $PlanPrescribedStrengthSetsTable,
        PlanPrescribedStrengthSet,
        $$PlanPrescribedStrengthSetsTableFilterComposer,
        $$PlanPrescribedStrengthSetsTableOrderingComposer,
        $$PlanPrescribedStrengthSetsTableAnnotationComposer,
        $$PlanPrescribedStrengthSetsTableCreateCompanionBuilder,
        $$PlanPrescribedStrengthSetsTableUpdateCompanionBuilder,
        (
          PlanPrescribedStrengthSet,
          BaseReferences<_$AppDb, $PlanPrescribedStrengthSetsTable,
              PlanPrescribedStrengthSet>
        ),
        PlanPrescribedStrengthSet,
        PrefetchHooks Function()>;
typedef $$PlanPrescribedRunsTableCreateCompanionBuilder
    = PlanPrescribedRunsCompanion Function({
  required String id,
  required String planDayId,
  Value<String?> dayLabel,
  Value<String?> liftFocus,
  Value<String?> runType,
  Value<String?> durationText,
  Value<String?> targetPace,
  Value<String?> effortHrGuardrails,
  Value<String?> notes,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanPrescribedRunsTableUpdateCompanionBuilder
    = PlanPrescribedRunsCompanion Function({
  Value<String> id,
  Value<String> planDayId,
  Value<String?> dayLabel,
  Value<String?> liftFocus,
  Value<String?> runType,
  Value<String?> durationText,
  Value<String?> targetPace,
  Value<String?> effortHrGuardrails,
  Value<String?> notes,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanPrescribedRunsTableFilterComposer
    extends Composer<_$AppDb, $PlanPrescribedRunsTable> {
  $$PlanPrescribedRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dayLabel => $composableBuilder(
      column: $table.dayLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get liftFocus => $composableBuilder(
      column: $table.liftFocus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runType => $composableBuilder(
      column: $table.runType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get durationText => $composableBuilder(
      column: $table.durationText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetPace => $composableBuilder(
      column: $table.targetPace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effortHrGuardrails => $composableBuilder(
      column: $table.effortHrGuardrails,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanPrescribedRunsTableOrderingComposer
    extends Composer<_$AppDb, $PlanPrescribedRunsTable> {
  $$PlanPrescribedRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDayId => $composableBuilder(
      column: $table.planDayId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dayLabel => $composableBuilder(
      column: $table.dayLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get liftFocus => $composableBuilder(
      column: $table.liftFocus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runType => $composableBuilder(
      column: $table.runType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get durationText => $composableBuilder(
      column: $table.durationText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetPace => $composableBuilder(
      column: $table.targetPace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effortHrGuardrails => $composableBuilder(
      column: $table.effortHrGuardrails,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanPrescribedRunsTableAnnotationComposer
    extends Composer<_$AppDb, $PlanPrescribedRunsTable> {
  $$PlanPrescribedRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDayId =>
      $composableBuilder(column: $table.planDayId, builder: (column) => column);

  GeneratedColumn<String> get dayLabel =>
      $composableBuilder(column: $table.dayLabel, builder: (column) => column);

  GeneratedColumn<String> get liftFocus =>
      $composableBuilder(column: $table.liftFocus, builder: (column) => column);

  GeneratedColumn<String> get runType =>
      $composableBuilder(column: $table.runType, builder: (column) => column);

  GeneratedColumn<String> get durationText => $composableBuilder(
      column: $table.durationText, builder: (column) => column);

  GeneratedColumn<String> get targetPace => $composableBuilder(
      column: $table.targetPace, builder: (column) => column);

  GeneratedColumn<String> get effortHrGuardrails => $composableBuilder(
      column: $table.effortHrGuardrails, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanPrescribedRunsTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanPrescribedRunsTable,
    PlanPrescribedRun,
    $$PlanPrescribedRunsTableFilterComposer,
    $$PlanPrescribedRunsTableOrderingComposer,
    $$PlanPrescribedRunsTableAnnotationComposer,
    $$PlanPrescribedRunsTableCreateCompanionBuilder,
    $$PlanPrescribedRunsTableUpdateCompanionBuilder,
    (
      PlanPrescribedRun,
      BaseReferences<_$AppDb, $PlanPrescribedRunsTable, PlanPrescribedRun>
    ),
    PlanPrescribedRun,
    PrefetchHooks Function()> {
  $$PlanPrescribedRunsTableTableManager(
      _$AppDb db, $PlanPrescribedRunsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanPrescribedRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanPrescribedRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanPrescribedRunsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planDayId = const Value.absent(),
            Value<String?> dayLabel = const Value.absent(),
            Value<String?> liftFocus = const Value.absent(),
            Value<String?> runType = const Value.absent(),
            Value<String?> durationText = const Value.absent(),
            Value<String?> targetPace = const Value.absent(),
            Value<String?> effortHrGuardrails = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanPrescribedRunsCompanion(
            id: id,
            planDayId: planDayId,
            dayLabel: dayLabel,
            liftFocus: liftFocus,
            runType: runType,
            durationText: durationText,
            targetPace: targetPace,
            effortHrGuardrails: effortHrGuardrails,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planDayId,
            Value<String?> dayLabel = const Value.absent(),
            Value<String?> liftFocus = const Value.absent(),
            Value<String?> runType = const Value.absent(),
            Value<String?> durationText = const Value.absent(),
            Value<String?> targetPace = const Value.absent(),
            Value<String?> effortHrGuardrails = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanPrescribedRunsCompanion.insert(
            id: id,
            planDayId: planDayId,
            dayLabel: dayLabel,
            liftFocus: liftFocus,
            runType: runType,
            durationText: durationText,
            targetPace: targetPace,
            effortHrGuardrails: effortHrGuardrails,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanPrescribedRunsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PlanPrescribedRunsTable,
    PlanPrescribedRun,
    $$PlanPrescribedRunsTableFilterComposer,
    $$PlanPrescribedRunsTableOrderingComposer,
    $$PlanPrescribedRunsTableAnnotationComposer,
    $$PlanPrescribedRunsTableCreateCompanionBuilder,
    $$PlanPrescribedRunsTableUpdateCompanionBuilder,
    (
      PlanPrescribedRun,
      BaseReferences<_$AppDb, $PlanPrescribedRunsTable, PlanPrescribedRun>
    ),
    PlanPrescribedRun,
    PrefetchHooks Function()>;
typedef $$PlanLongRangeWeeksTableCreateCompanionBuilder
    = PlanLongRangeWeeksCompanion Function({
  required String id,
  required String weekLabel,
  Value<int?> weekNumber,
  required String weekStart,
  required String weekEnd,
  Value<String?> runFocus,
  Value<String?> strengthFocus,
  Value<String?> strengthProgressionExpectation,
  Value<String?> primaryProgressionTarget,
  Value<String?> recoveryEmphasis,
  Value<bool> deload,
  Value<String?> notes,
  required String source,
  Value<String?> lastPlanCycleId,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$PlanLongRangeWeeksTableUpdateCompanionBuilder
    = PlanLongRangeWeeksCompanion Function({
  Value<String> id,
  Value<String> weekLabel,
  Value<int?> weekNumber,
  Value<String> weekStart,
  Value<String> weekEnd,
  Value<String?> runFocus,
  Value<String?> strengthFocus,
  Value<String?> strengthProgressionExpectation,
  Value<String?> primaryProgressionTarget,
  Value<String?> recoveryEmphasis,
  Value<bool> deload,
  Value<String?> notes,
  Value<String> source,
  Value<String?> lastPlanCycleId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$PlanLongRangeWeeksTableFilterComposer
    extends Composer<_$AppDb, $PlanLongRangeWeeksTable> {
  $$PlanLongRangeWeeksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekLabel => $composableBuilder(
      column: $table.weekLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get runFocus => $composableBuilder(
      column: $table.runFocus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strengthFocus => $composableBuilder(
      column: $table.strengthFocus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryProgressionTarget => $composableBuilder(
      column: $table.primaryProgressionTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recoveryEmphasis => $composableBuilder(
      column: $table.recoveryEmphasis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deload => $composableBuilder(
      column: $table.deload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastPlanCycleId => $composableBuilder(
      column: $table.lastPlanCycleId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PlanLongRangeWeeksTableOrderingComposer
    extends Composer<_$AppDb, $PlanLongRangeWeeksTable> {
  $$PlanLongRangeWeeksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekLabel => $composableBuilder(
      column: $table.weekLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get runFocus => $composableBuilder(
      column: $table.runFocus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strengthFocus => $composableBuilder(
      column: $table.strengthFocus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryProgressionTarget => $composableBuilder(
      column: $table.primaryProgressionTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recoveryEmphasis => $composableBuilder(
      column: $table.recoveryEmphasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deload => $composableBuilder(
      column: $table.deload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastPlanCycleId => $composableBuilder(
      column: $table.lastPlanCycleId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanLongRangeWeeksTableAnnotationComposer
    extends Composer<_$AppDb, $PlanLongRangeWeeksTable> {
  $$PlanLongRangeWeeksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get weekLabel =>
      $composableBuilder(column: $table.weekLabel, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get weekEnd =>
      $composableBuilder(column: $table.weekEnd, builder: (column) => column);

  GeneratedColumn<String> get runFocus =>
      $composableBuilder(column: $table.runFocus, builder: (column) => column);

  GeneratedColumn<String> get strengthFocus => $composableBuilder(
      column: $table.strengthFocus, builder: (column) => column);

  GeneratedColumn<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => column);

  GeneratedColumn<String> get primaryProgressionTarget => $composableBuilder(
      column: $table.primaryProgressionTarget, builder: (column) => column);

  GeneratedColumn<String> get recoveryEmphasis => $composableBuilder(
      column: $table.recoveryEmphasis, builder: (column) => column);

  GeneratedColumn<bool> get deload =>
      $composableBuilder(column: $table.deload, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get lastPlanCycleId => $composableBuilder(
      column: $table.lastPlanCycleId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlanLongRangeWeeksTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanLongRangeWeeksTable,
    PlanLongRangeWeek,
    $$PlanLongRangeWeeksTableFilterComposer,
    $$PlanLongRangeWeeksTableOrderingComposer,
    $$PlanLongRangeWeeksTableAnnotationComposer,
    $$PlanLongRangeWeeksTableCreateCompanionBuilder,
    $$PlanLongRangeWeeksTableUpdateCompanionBuilder,
    (
      PlanLongRangeWeek,
      BaseReferences<_$AppDb, $PlanLongRangeWeeksTable, PlanLongRangeWeek>
    ),
    PlanLongRangeWeek,
    PrefetchHooks Function()> {
  $$PlanLongRangeWeeksTableTableManager(
      _$AppDb db, $PlanLongRangeWeeksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanLongRangeWeeksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanLongRangeWeeksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanLongRangeWeeksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> weekLabel = const Value.absent(),
            Value<int?> weekNumber = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<String> weekEnd = const Value.absent(),
            Value<String?> runFocus = const Value.absent(),
            Value<String?> strengthFocus = const Value.absent(),
            Value<String?> strengthProgressionExpectation =
                const Value.absent(),
            Value<String?> primaryProgressionTarget = const Value.absent(),
            Value<String?> recoveryEmphasis = const Value.absent(),
            Value<bool> deload = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> lastPlanCycleId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanLongRangeWeeksCompanion(
            id: id,
            weekLabel: weekLabel,
            weekNumber: weekNumber,
            weekStart: weekStart,
            weekEnd: weekEnd,
            runFocus: runFocus,
            strengthFocus: strengthFocus,
            strengthProgressionExpectation: strengthProgressionExpectation,
            primaryProgressionTarget: primaryProgressionTarget,
            recoveryEmphasis: recoveryEmphasis,
            deload: deload,
            notes: notes,
            source: source,
            lastPlanCycleId: lastPlanCycleId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String weekLabel,
            Value<int?> weekNumber = const Value.absent(),
            required String weekStart,
            required String weekEnd,
            Value<String?> runFocus = const Value.absent(),
            Value<String?> strengthFocus = const Value.absent(),
            Value<String?> strengthProgressionExpectation =
                const Value.absent(),
            Value<String?> primaryProgressionTarget = const Value.absent(),
            Value<String?> recoveryEmphasis = const Value.absent(),
            Value<bool> deload = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String source,
            Value<String?> lastPlanCycleId = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanLongRangeWeeksCompanion.insert(
            id: id,
            weekLabel: weekLabel,
            weekNumber: weekNumber,
            weekStart: weekStart,
            weekEnd: weekEnd,
            runFocus: runFocus,
            strengthFocus: strengthFocus,
            strengthProgressionExpectation: strengthProgressionExpectation,
            primaryProgressionTarget: primaryProgressionTarget,
            recoveryEmphasis: recoveryEmphasis,
            deload: deload,
            notes: notes,
            source: source,
            lastPlanCycleId: lastPlanCycleId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanLongRangeWeeksTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PlanLongRangeWeeksTable,
    PlanLongRangeWeek,
    $$PlanLongRangeWeeksTableFilterComposer,
    $$PlanLongRangeWeeksTableOrderingComposer,
    $$PlanLongRangeWeeksTableAnnotationComposer,
    $$PlanLongRangeWeeksTableCreateCompanionBuilder,
    $$PlanLongRangeWeeksTableUpdateCompanionBuilder,
    (
      PlanLongRangeWeek,
      BaseReferences<_$AppDb, $PlanLongRangeWeeksTable, PlanLongRangeWeek>
    ),
    PlanLongRangeWeek,
    PrefetchHooks Function()>;
typedef $$PlanLongRangeWeekPerformanceTableCreateCompanionBuilder
    = PlanLongRangeWeekPerformanceCompanion Function({
  required String id,
  Value<String?> planLongRangeWeekId,
  Value<String?> weekLabel,
  Value<int?> weekNumber,
  required String weekStart,
  required String weekEnd,
  Value<String?> evaluatedPlanCycleId,
  required String evaluationSource,
  required int plannedDayCount,
  required int completedPlanDays,
  required int plannedRunDays,
  required int actualRunDays,
  required int plannedRunSessions,
  required int actualRunSessions,
  required int plannedStrengthExercises,
  required int actualStrengthExercises,
  required int plannedStrengthSets,
  required int actualStrengthSets,
  Value<String?> strengthProgressionExpectation,
  Value<String?> strengthProgressionEvaluation,
  Value<double?> actualRunDistanceM,
  Value<int?> actualRunDurationS,
  Value<String?> metricsJson,
  required int capturedAt,
  Value<int> rowid,
});
typedef $$PlanLongRangeWeekPerformanceTableUpdateCompanionBuilder
    = PlanLongRangeWeekPerformanceCompanion Function({
  Value<String> id,
  Value<String?> planLongRangeWeekId,
  Value<String?> weekLabel,
  Value<int?> weekNumber,
  Value<String> weekStart,
  Value<String> weekEnd,
  Value<String?> evaluatedPlanCycleId,
  Value<String> evaluationSource,
  Value<int> plannedDayCount,
  Value<int> completedPlanDays,
  Value<int> plannedRunDays,
  Value<int> actualRunDays,
  Value<int> plannedRunSessions,
  Value<int> actualRunSessions,
  Value<int> plannedStrengthExercises,
  Value<int> actualStrengthExercises,
  Value<int> plannedStrengthSets,
  Value<int> actualStrengthSets,
  Value<String?> strengthProgressionExpectation,
  Value<String?> strengthProgressionEvaluation,
  Value<double?> actualRunDistanceM,
  Value<int?> actualRunDurationS,
  Value<String?> metricsJson,
  Value<int> capturedAt,
  Value<int> rowid,
});

class $$PlanLongRangeWeekPerformanceTableFilterComposer
    extends Composer<_$AppDb, $PlanLongRangeWeekPerformanceTable> {
  $$PlanLongRangeWeekPerformanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planLongRangeWeekId => $composableBuilder(
      column: $table.planLongRangeWeekId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekLabel => $composableBuilder(
      column: $table.weekLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evaluatedPlanCycleId => $composableBuilder(
      column: $table.evaluatedPlanCycleId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evaluationSource => $composableBuilder(
      column: $table.evaluationSource,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedDayCount => $composableBuilder(
      column: $table.plannedDayCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedPlanDays => $composableBuilder(
      column: $table.completedPlanDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedRunDays => $composableBuilder(
      column: $table.plannedRunDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualRunDays => $composableBuilder(
      column: $table.actualRunDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedRunSessions => $composableBuilder(
      column: $table.plannedRunSessions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualRunSessions => $composableBuilder(
      column: $table.actualRunSessions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedStrengthExercises => $composableBuilder(
      column: $table.plannedStrengthExercises,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualStrengthExercises => $composableBuilder(
      column: $table.actualStrengthExercises,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedStrengthSets => $composableBuilder(
      column: $table.plannedStrengthSets,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualStrengthSets => $composableBuilder(
      column: $table.actualStrengthSets,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strengthProgressionEvaluation => $composableBuilder(
      column: $table.strengthProgressionEvaluation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualRunDistanceM => $composableBuilder(
      column: $table.actualRunDistanceM,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualRunDurationS => $composableBuilder(
      column: $table.actualRunDurationS,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricsJson => $composableBuilder(
      column: $table.metricsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));
}

class $$PlanLongRangeWeekPerformanceTableOrderingComposer
    extends Composer<_$AppDb, $PlanLongRangeWeekPerformanceTable> {
  $$PlanLongRangeWeekPerformanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planLongRangeWeekId => $composableBuilder(
      column: $table.planLongRangeWeekId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekLabel => $composableBuilder(
      column: $table.weekLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekEnd => $composableBuilder(
      column: $table.weekEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evaluatedPlanCycleId => $composableBuilder(
      column: $table.evaluatedPlanCycleId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evaluationSource => $composableBuilder(
      column: $table.evaluationSource,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedDayCount => $composableBuilder(
      column: $table.plannedDayCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedPlanDays => $composableBuilder(
      column: $table.completedPlanDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedRunDays => $composableBuilder(
      column: $table.plannedRunDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualRunDays => $composableBuilder(
      column: $table.actualRunDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedRunSessions => $composableBuilder(
      column: $table.plannedRunSessions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualRunSessions => $composableBuilder(
      column: $table.actualRunSessions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedStrengthExercises => $composableBuilder(
      column: $table.plannedStrengthExercises,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualStrengthExercises => $composableBuilder(
      column: $table.actualStrengthExercises,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedStrengthSets => $composableBuilder(
      column: $table.plannedStrengthSets,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualStrengthSets => $composableBuilder(
      column: $table.actualStrengthSets,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strengthProgressionEvaluation =>
      $composableBuilder(
          column: $table.strengthProgressionEvaluation,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualRunDistanceM => $composableBuilder(
      column: $table.actualRunDistanceM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualRunDurationS => $composableBuilder(
      column: $table.actualRunDurationS,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricsJson => $composableBuilder(
      column: $table.metricsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanLongRangeWeekPerformanceTableAnnotationComposer
    extends Composer<_$AppDb, $PlanLongRangeWeekPerformanceTable> {
  $$PlanLongRangeWeekPerformanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planLongRangeWeekId => $composableBuilder(
      column: $table.planLongRangeWeekId, builder: (column) => column);

  GeneratedColumn<String> get weekLabel =>
      $composableBuilder(column: $table.weekLabel, builder: (column) => column);

  GeneratedColumn<int> get weekNumber => $composableBuilder(
      column: $table.weekNumber, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get weekEnd =>
      $composableBuilder(column: $table.weekEnd, builder: (column) => column);

  GeneratedColumn<String> get evaluatedPlanCycleId => $composableBuilder(
      column: $table.evaluatedPlanCycleId, builder: (column) => column);

  GeneratedColumn<String> get evaluationSource => $composableBuilder(
      column: $table.evaluationSource, builder: (column) => column);

  GeneratedColumn<int> get plannedDayCount => $composableBuilder(
      column: $table.plannedDayCount, builder: (column) => column);

  GeneratedColumn<int> get completedPlanDays => $composableBuilder(
      column: $table.completedPlanDays, builder: (column) => column);

  GeneratedColumn<int> get plannedRunDays => $composableBuilder(
      column: $table.plannedRunDays, builder: (column) => column);

  GeneratedColumn<int> get actualRunDays => $composableBuilder(
      column: $table.actualRunDays, builder: (column) => column);

  GeneratedColumn<int> get plannedRunSessions => $composableBuilder(
      column: $table.plannedRunSessions, builder: (column) => column);

  GeneratedColumn<int> get actualRunSessions => $composableBuilder(
      column: $table.actualRunSessions, builder: (column) => column);

  GeneratedColumn<int> get plannedStrengthExercises => $composableBuilder(
      column: $table.plannedStrengthExercises, builder: (column) => column);

  GeneratedColumn<int> get actualStrengthExercises => $composableBuilder(
      column: $table.actualStrengthExercises, builder: (column) => column);

  GeneratedColumn<int> get plannedStrengthSets => $composableBuilder(
      column: $table.plannedStrengthSets, builder: (column) => column);

  GeneratedColumn<int> get actualStrengthSets => $composableBuilder(
      column: $table.actualStrengthSets, builder: (column) => column);

  GeneratedColumn<String> get strengthProgressionExpectation =>
      $composableBuilder(
          column: $table.strengthProgressionExpectation,
          builder: (column) => column);

  GeneratedColumn<String> get strengthProgressionEvaluation =>
      $composableBuilder(
          column: $table.strengthProgressionEvaluation,
          builder: (column) => column);

  GeneratedColumn<double> get actualRunDistanceM => $composableBuilder(
      column: $table.actualRunDistanceM, builder: (column) => column);

  GeneratedColumn<int> get actualRunDurationS => $composableBuilder(
      column: $table.actualRunDurationS, builder: (column) => column);

  GeneratedColumn<String> get metricsJson => $composableBuilder(
      column: $table.metricsJson, builder: (column) => column);

  GeneratedColumn<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);
}

class $$PlanLongRangeWeekPerformanceTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanLongRangeWeekPerformanceTable,
    PlanLongRangeWeekPerformanceData,
    $$PlanLongRangeWeekPerformanceTableFilterComposer,
    $$PlanLongRangeWeekPerformanceTableOrderingComposer,
    $$PlanLongRangeWeekPerformanceTableAnnotationComposer,
    $$PlanLongRangeWeekPerformanceTableCreateCompanionBuilder,
    $$PlanLongRangeWeekPerformanceTableUpdateCompanionBuilder,
    (
      PlanLongRangeWeekPerformanceData,
      BaseReferences<_$AppDb, $PlanLongRangeWeekPerformanceTable,
          PlanLongRangeWeekPerformanceData>
    ),
    PlanLongRangeWeekPerformanceData,
    PrefetchHooks Function()> {
  $$PlanLongRangeWeekPerformanceTableTableManager(
      _$AppDb db, $PlanLongRangeWeekPerformanceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanLongRangeWeekPerformanceTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanLongRangeWeekPerformanceTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanLongRangeWeekPerformanceTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> planLongRangeWeekId = const Value.absent(),
            Value<String?> weekLabel = const Value.absent(),
            Value<int?> weekNumber = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<String> weekEnd = const Value.absent(),
            Value<String?> evaluatedPlanCycleId = const Value.absent(),
            Value<String> evaluationSource = const Value.absent(),
            Value<int> plannedDayCount = const Value.absent(),
            Value<int> completedPlanDays = const Value.absent(),
            Value<int> plannedRunDays = const Value.absent(),
            Value<int> actualRunDays = const Value.absent(),
            Value<int> plannedRunSessions = const Value.absent(),
            Value<int> actualRunSessions = const Value.absent(),
            Value<int> plannedStrengthExercises = const Value.absent(),
            Value<int> actualStrengthExercises = const Value.absent(),
            Value<int> plannedStrengthSets = const Value.absent(),
            Value<int> actualStrengthSets = const Value.absent(),
            Value<String?> strengthProgressionExpectation =
                const Value.absent(),
            Value<String?> strengthProgressionEvaluation = const Value.absent(),
            Value<double?> actualRunDistanceM = const Value.absent(),
            Value<int?> actualRunDurationS = const Value.absent(),
            Value<String?> metricsJson = const Value.absent(),
            Value<int> capturedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanLongRangeWeekPerformanceCompanion(
            id: id,
            planLongRangeWeekId: planLongRangeWeekId,
            weekLabel: weekLabel,
            weekNumber: weekNumber,
            weekStart: weekStart,
            weekEnd: weekEnd,
            evaluatedPlanCycleId: evaluatedPlanCycleId,
            evaluationSource: evaluationSource,
            plannedDayCount: plannedDayCount,
            completedPlanDays: completedPlanDays,
            plannedRunDays: plannedRunDays,
            actualRunDays: actualRunDays,
            plannedRunSessions: plannedRunSessions,
            actualRunSessions: actualRunSessions,
            plannedStrengthExercises: plannedStrengthExercises,
            actualStrengthExercises: actualStrengthExercises,
            plannedStrengthSets: plannedStrengthSets,
            actualStrengthSets: actualStrengthSets,
            strengthProgressionExpectation: strengthProgressionExpectation,
            strengthProgressionEvaluation: strengthProgressionEvaluation,
            actualRunDistanceM: actualRunDistanceM,
            actualRunDurationS: actualRunDurationS,
            metricsJson: metricsJson,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> planLongRangeWeekId = const Value.absent(),
            Value<String?> weekLabel = const Value.absent(),
            Value<int?> weekNumber = const Value.absent(),
            required String weekStart,
            required String weekEnd,
            Value<String?> evaluatedPlanCycleId = const Value.absent(),
            required String evaluationSource,
            required int plannedDayCount,
            required int completedPlanDays,
            required int plannedRunDays,
            required int actualRunDays,
            required int plannedRunSessions,
            required int actualRunSessions,
            required int plannedStrengthExercises,
            required int actualStrengthExercises,
            required int plannedStrengthSets,
            required int actualStrengthSets,
            Value<String?> strengthProgressionExpectation =
                const Value.absent(),
            Value<String?> strengthProgressionEvaluation = const Value.absent(),
            Value<double?> actualRunDistanceM = const Value.absent(),
            Value<int?> actualRunDurationS = const Value.absent(),
            Value<String?> metricsJson = const Value.absent(),
            required int capturedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanLongRangeWeekPerformanceCompanion.insert(
            id: id,
            planLongRangeWeekId: planLongRangeWeekId,
            weekLabel: weekLabel,
            weekNumber: weekNumber,
            weekStart: weekStart,
            weekEnd: weekEnd,
            evaluatedPlanCycleId: evaluatedPlanCycleId,
            evaluationSource: evaluationSource,
            plannedDayCount: plannedDayCount,
            completedPlanDays: completedPlanDays,
            plannedRunDays: plannedRunDays,
            actualRunDays: actualRunDays,
            plannedRunSessions: plannedRunSessions,
            actualRunSessions: actualRunSessions,
            plannedStrengthExercises: plannedStrengthExercises,
            actualStrengthExercises: actualStrengthExercises,
            plannedStrengthSets: plannedStrengthSets,
            actualStrengthSets: actualStrengthSets,
            strengthProgressionExpectation: strengthProgressionExpectation,
            strengthProgressionEvaluation: strengthProgressionEvaluation,
            actualRunDistanceM: actualRunDistanceM,
            actualRunDurationS: actualRunDurationS,
            metricsJson: metricsJson,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanLongRangeWeekPerformanceTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $PlanLongRangeWeekPerformanceTable,
        PlanLongRangeWeekPerformanceData,
        $$PlanLongRangeWeekPerformanceTableFilterComposer,
        $$PlanLongRangeWeekPerformanceTableOrderingComposer,
        $$PlanLongRangeWeekPerformanceTableAnnotationComposer,
        $$PlanLongRangeWeekPerformanceTableCreateCompanionBuilder,
        $$PlanLongRangeWeekPerformanceTableUpdateCompanionBuilder,
        (
          PlanLongRangeWeekPerformanceData,
          BaseReferences<_$AppDb, $PlanLongRangeWeekPerformanceTable,
              PlanLongRangeWeekPerformanceData>
        ),
        PlanLongRangeWeekPerformanceData,
        PrefetchHooks Function()>;
typedef $$PlanSummarySnapshotsTableCreateCompanionBuilder
    = PlanSummarySnapshotsCompanion Function({
  required String id,
  required String planCycleId,
  required String tabName,
  required String snapshotJson,
  required int createdAt,
  Value<int> rowid,
});
typedef $$PlanSummarySnapshotsTableUpdateCompanionBuilder
    = PlanSummarySnapshotsCompanion Function({
  Value<String> id,
  Value<String> planCycleId,
  Value<String> tabName,
  Value<String> snapshotJson,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$PlanSummarySnapshotsTableFilterComposer
    extends Composer<_$AppDb, $PlanSummarySnapshotsTable> {
  $$PlanSummarySnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tabName => $composableBuilder(
      column: $table.tabName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PlanSummarySnapshotsTableOrderingComposer
    extends Composer<_$AppDb, $PlanSummarySnapshotsTable> {
  $$PlanSummarySnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tabName => $composableBuilder(
      column: $table.tabName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PlanSummarySnapshotsTableAnnotationComposer
    extends Composer<_$AppDb, $PlanSummarySnapshotsTable> {
  $$PlanSummarySnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planCycleId => $composableBuilder(
      column: $table.planCycleId, builder: (column) => column);

  GeneratedColumn<String> get tabName =>
      $composableBuilder(column: $table.tabName, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlanSummarySnapshotsTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanSummarySnapshotsTable,
    PlanSummarySnapshot,
    $$PlanSummarySnapshotsTableFilterComposer,
    $$PlanSummarySnapshotsTableOrderingComposer,
    $$PlanSummarySnapshotsTableAnnotationComposer,
    $$PlanSummarySnapshotsTableCreateCompanionBuilder,
    $$PlanSummarySnapshotsTableUpdateCompanionBuilder,
    (
      PlanSummarySnapshot,
      BaseReferences<_$AppDb, $PlanSummarySnapshotsTable, PlanSummarySnapshot>
    ),
    PlanSummarySnapshot,
    PrefetchHooks Function()> {
  $$PlanSummarySnapshotsTableTableManager(
      _$AppDb db, $PlanSummarySnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanSummarySnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanSummarySnapshotsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanSummarySnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planCycleId = const Value.absent(),
            Value<String> tabName = const Value.absent(),
            Value<String> snapshotJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanSummarySnapshotsCompanion(
            id: id,
            planCycleId: planCycleId,
            tabName: tabName,
            snapshotJson: snapshotJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planCycleId,
            required String tabName,
            required String snapshotJson,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanSummarySnapshotsCompanion.insert(
            id: id,
            planCycleId: planCycleId,
            tabName: tabName,
            snapshotJson: snapshotJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanSummarySnapshotsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $PlanSummarySnapshotsTable,
        PlanSummarySnapshot,
        $$PlanSummarySnapshotsTableFilterComposer,
        $$PlanSummarySnapshotsTableOrderingComposer,
        $$PlanSummarySnapshotsTableAnnotationComposer,
        $$PlanSummarySnapshotsTableCreateCompanionBuilder,
        $$PlanSummarySnapshotsTableUpdateCompanionBuilder,
        (
          PlanSummarySnapshot,
          BaseReferences<_$AppDb, $PlanSummarySnapshotsTable,
              PlanSummarySnapshot>
        ),
        PlanSummarySnapshot,
        PrefetchHooks Function()>;
typedef $$PlanImportAuditTableCreateCompanionBuilder = PlanImportAuditCompanion
    Function({
  required String id,
  required int importedAt,
  required String fileName,
  required bool success,
  required String detailsJson,
  Value<String?> conflictReportPath,
  Value<int> rowid,
});
typedef $$PlanImportAuditTableUpdateCompanionBuilder = PlanImportAuditCompanion
    Function({
  Value<String> id,
  Value<int> importedAt,
  Value<String> fileName,
  Value<bool> success,
  Value<String> detailsJson,
  Value<String?> conflictReportPath,
  Value<int> rowid,
});

class $$PlanImportAuditTableFilterComposer
    extends Composer<_$AppDb, $PlanImportAuditTable> {
  $$PlanImportAuditTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conflictReportPath => $composableBuilder(
      column: $table.conflictReportPath,
      builder: (column) => ColumnFilters(column));
}

class $$PlanImportAuditTableOrderingComposer
    extends Composer<_$AppDb, $PlanImportAuditTable> {
  $$PlanImportAuditTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get success => $composableBuilder(
      column: $table.success, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conflictReportPath => $composableBuilder(
      column: $table.conflictReportPath,
      builder: (column) => ColumnOrderings(column));
}

class $$PlanImportAuditTableAnnotationComposer
    extends Composer<_$AppDb, $PlanImportAuditTable> {
  $$PlanImportAuditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get detailsJson => $composableBuilder(
      column: $table.detailsJson, builder: (column) => column);

  GeneratedColumn<String> get conflictReportPath => $composableBuilder(
      column: $table.conflictReportPath, builder: (column) => column);
}

class $$PlanImportAuditTableTableManager extends RootTableManager<
    _$AppDb,
    $PlanImportAuditTable,
    PlanImportAuditData,
    $$PlanImportAuditTableFilterComposer,
    $$PlanImportAuditTableOrderingComposer,
    $$PlanImportAuditTableAnnotationComposer,
    $$PlanImportAuditTableCreateCompanionBuilder,
    $$PlanImportAuditTableUpdateCompanionBuilder,
    (
      PlanImportAuditData,
      BaseReferences<_$AppDb, $PlanImportAuditTable, PlanImportAuditData>
    ),
    PlanImportAuditData,
    PrefetchHooks Function()> {
  $$PlanImportAuditTableTableManager(_$AppDb db, $PlanImportAuditTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanImportAuditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanImportAuditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanImportAuditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> importedAt = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<bool> success = const Value.absent(),
            Value<String> detailsJson = const Value.absent(),
            Value<String?> conflictReportPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanImportAuditCompanion(
            id: id,
            importedAt: importedAt,
            fileName: fileName,
            success: success,
            detailsJson: detailsJson,
            conflictReportPath: conflictReportPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int importedAt,
            required String fileName,
            required bool success,
            required String detailsJson,
            Value<String?> conflictReportPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanImportAuditCompanion.insert(
            id: id,
            importedAt: importedAt,
            fileName: fileName,
            success: success,
            detailsJson: detailsJson,
            conflictReportPath: conflictReportPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanImportAuditTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PlanImportAuditTable,
    PlanImportAuditData,
    $$PlanImportAuditTableFilterComposer,
    $$PlanImportAuditTableOrderingComposer,
    $$PlanImportAuditTableAnnotationComposer,
    $$PlanImportAuditTableCreateCompanionBuilder,
    $$PlanImportAuditTableUpdateCompanionBuilder,
    (
      PlanImportAuditData,
      BaseReferences<_$AppDb, $PlanImportAuditTable, PlanImportAuditData>
    ),
    PlanImportAuditData,
    PrefetchHooks Function()>;
typedef $$CloudWorkspacesTableCreateCompanionBuilder = CloudWorkspacesCompanion
    Function({
  required String id,
  required String name,
  required int createdAt,
  required String createdByUserId,
  Value<int> rowid,
});
typedef $$CloudWorkspacesTableUpdateCompanionBuilder = CloudWorkspacesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> createdAt,
  Value<String> createdByUserId,
  Value<int> rowid,
});

class $$CloudWorkspacesTableFilterComposer
    extends Composer<_$AppDb, $CloudWorkspacesTable> {
  $$CloudWorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$CloudWorkspacesTableOrderingComposer
    extends Composer<_$AppDb, $CloudWorkspacesTable> {
  $$CloudWorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$CloudWorkspacesTableAnnotationComposer
    extends Composer<_$AppDb, $CloudWorkspacesTable> {
  $$CloudWorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);
}

class $$CloudWorkspacesTableTableManager extends RootTableManager<
    _$AppDb,
    $CloudWorkspacesTable,
    CloudWorkspace,
    $$CloudWorkspacesTableFilterComposer,
    $$CloudWorkspacesTableOrderingComposer,
    $$CloudWorkspacesTableAnnotationComposer,
    $$CloudWorkspacesTableCreateCompanionBuilder,
    $$CloudWorkspacesTableUpdateCompanionBuilder,
    (
      CloudWorkspace,
      BaseReferences<_$AppDb, $CloudWorkspacesTable, CloudWorkspace>
    ),
    CloudWorkspace,
    PrefetchHooks Function()> {
  $$CloudWorkspacesTableTableManager(_$AppDb db, $CloudWorkspacesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudWorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudWorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudWorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspacesCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int createdAt,
            required String createdByUserId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspacesCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudWorkspacesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $CloudWorkspacesTable,
    CloudWorkspace,
    $$CloudWorkspacesTableFilterComposer,
    $$CloudWorkspacesTableOrderingComposer,
    $$CloudWorkspacesTableAnnotationComposer,
    $$CloudWorkspacesTableCreateCompanionBuilder,
    $$CloudWorkspacesTableUpdateCompanionBuilder,
    (
      CloudWorkspace,
      BaseReferences<_$AppDb, $CloudWorkspacesTable, CloudWorkspace>
    ),
    CloudWorkspace,
    PrefetchHooks Function()>;
typedef $$CloudWorkspaceMembershipsTableCreateCompanionBuilder
    = CloudWorkspaceMembershipsCompanion Function({
  required String id,
  required String workspaceId,
  required String userId,
  required String userEmail,
  Value<String?> displayName,
  required String role,
  required String status,
  required int createdAt,
  required String createdByUserId,
  Value<int> rowid,
});
typedef $$CloudWorkspaceMembershipsTableUpdateCompanionBuilder
    = CloudWorkspaceMembershipsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> userId,
  Value<String> userEmail,
  Value<String?> displayName,
  Value<String> role,
  Value<String> status,
  Value<int> createdAt,
  Value<String> createdByUserId,
  Value<int> rowid,
});

class $$CloudWorkspaceMembershipsTableFilterComposer
    extends Composer<_$AppDb, $CloudWorkspaceMembershipsTable> {
  $$CloudWorkspaceMembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userEmail => $composableBuilder(
      column: $table.userEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$CloudWorkspaceMembershipsTableOrderingComposer
    extends Composer<_$AppDb, $CloudWorkspaceMembershipsTable> {
  $$CloudWorkspaceMembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userEmail => $composableBuilder(
      column: $table.userEmail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$CloudWorkspaceMembershipsTableAnnotationComposer
    extends Composer<_$AppDb, $CloudWorkspaceMembershipsTable> {
  $$CloudWorkspaceMembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userEmail =>
      $composableBuilder(column: $table.userEmail, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);
}

class $$CloudWorkspaceMembershipsTableTableManager extends RootTableManager<
    _$AppDb,
    $CloudWorkspaceMembershipsTable,
    CloudWorkspaceMembership,
    $$CloudWorkspaceMembershipsTableFilterComposer,
    $$CloudWorkspaceMembershipsTableOrderingComposer,
    $$CloudWorkspaceMembershipsTableAnnotationComposer,
    $$CloudWorkspaceMembershipsTableCreateCompanionBuilder,
    $$CloudWorkspaceMembershipsTableUpdateCompanionBuilder,
    (
      CloudWorkspaceMembership,
      BaseReferences<_$AppDb, $CloudWorkspaceMembershipsTable,
          CloudWorkspaceMembership>
    ),
    CloudWorkspaceMembership,
    PrefetchHooks Function()> {
  $$CloudWorkspaceMembershipsTableTableManager(
      _$AppDb db, $CloudWorkspaceMembershipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudWorkspaceMembershipsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudWorkspaceMembershipsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudWorkspaceMembershipsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> userEmail = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspaceMembershipsCompanion(
            id: id,
            workspaceId: workspaceId,
            userId: userId,
            userEmail: userEmail,
            displayName: displayName,
            role: role,
            status: status,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workspaceId,
            required String userId,
            required String userEmail,
            Value<String?> displayName = const Value.absent(),
            required String role,
            required String status,
            required int createdAt,
            required String createdByUserId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspaceMembershipsCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            userId: userId,
            userEmail: userEmail,
            displayName: displayName,
            role: role,
            status: status,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudWorkspaceMembershipsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $CloudWorkspaceMembershipsTable,
        CloudWorkspaceMembership,
        $$CloudWorkspaceMembershipsTableFilterComposer,
        $$CloudWorkspaceMembershipsTableOrderingComposer,
        $$CloudWorkspaceMembershipsTableAnnotationComposer,
        $$CloudWorkspaceMembershipsTableCreateCompanionBuilder,
        $$CloudWorkspaceMembershipsTableUpdateCompanionBuilder,
        (
          CloudWorkspaceMembership,
          BaseReferences<_$AppDb, $CloudWorkspaceMembershipsTable,
              CloudWorkspaceMembership>
        ),
        CloudWorkspaceMembership,
        PrefetchHooks Function()>;
typedef $$CloudAthleteProfilesTableCreateCompanionBuilder
    = CloudAthleteProfilesCompanion Function({
  required String id,
  required String workspaceId,
  required String name,
  Value<String?> dateOfBirth,
  Value<String?> notes,
  required int createdAt,
  required String createdByUserId,
  Value<int> rowid,
});
typedef $$CloudAthleteProfilesTableUpdateCompanionBuilder
    = CloudAthleteProfilesCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> name,
  Value<String?> dateOfBirth,
  Value<String?> notes,
  Value<int> createdAt,
  Value<String> createdByUserId,
  Value<int> rowid,
});

class $$CloudAthleteProfilesTableFilterComposer
    extends Composer<_$AppDb, $CloudAthleteProfilesTable> {
  $$CloudAthleteProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$CloudAthleteProfilesTableOrderingComposer
    extends Composer<_$AppDb, $CloudAthleteProfilesTable> {
  $$CloudAthleteProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$CloudAthleteProfilesTableAnnotationComposer
    extends Composer<_$AppDb, $CloudAthleteProfilesTable> {
  $$CloudAthleteProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);
}

class $$CloudAthleteProfilesTableTableManager extends RootTableManager<
    _$AppDb,
    $CloudAthleteProfilesTable,
    CloudAthleteProfile,
    $$CloudAthleteProfilesTableFilterComposer,
    $$CloudAthleteProfilesTableOrderingComposer,
    $$CloudAthleteProfilesTableAnnotationComposer,
    $$CloudAthleteProfilesTableCreateCompanionBuilder,
    $$CloudAthleteProfilesTableUpdateCompanionBuilder,
    (
      CloudAthleteProfile,
      BaseReferences<_$AppDb, $CloudAthleteProfilesTable, CloudAthleteProfile>
    ),
    CloudAthleteProfile,
    PrefetchHooks Function()> {
  $$CloudAthleteProfilesTableTableManager(
      _$AppDb db, $CloudAthleteProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudAthleteProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudAthleteProfilesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudAthleteProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> dateOfBirth = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudAthleteProfilesCompanion(
            id: id,
            workspaceId: workspaceId,
            name: name,
            dateOfBirth: dateOfBirth,
            notes: notes,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workspaceId,
            required String name,
            Value<String?> dateOfBirth = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required int createdAt,
            required String createdByUserId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudAthleteProfilesCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            name: name,
            dateOfBirth: dateOfBirth,
            notes: notes,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudAthleteProfilesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $CloudAthleteProfilesTable,
        CloudAthleteProfile,
        $$CloudAthleteProfilesTableFilterComposer,
        $$CloudAthleteProfilesTableOrderingComposer,
        $$CloudAthleteProfilesTableAnnotationComposer,
        $$CloudAthleteProfilesTableCreateCompanionBuilder,
        $$CloudAthleteProfilesTableUpdateCompanionBuilder,
        (
          CloudAthleteProfile,
          BaseReferences<_$AppDb, $CloudAthleteProfilesTable,
              CloudAthleteProfile>
        ),
        CloudAthleteProfile,
        PrefetchHooks Function()>;
typedef $$CloudAthleteProfileAssignmentsTableCreateCompanionBuilder
    = CloudAthleteProfileAssignmentsCompanion Function({
  required String id,
  required String workspaceId,
  required String athleteProfileId,
  required String userId,
  Value<bool> canView,
  Value<bool> canEdit,
  required int createdAt,
  required String createdByUserId,
  Value<int> rowid,
});
typedef $$CloudAthleteProfileAssignmentsTableUpdateCompanionBuilder
    = CloudAthleteProfileAssignmentsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> athleteProfileId,
  Value<String> userId,
  Value<bool> canView,
  Value<bool> canEdit,
  Value<int> createdAt,
  Value<String> createdByUserId,
  Value<int> rowid,
});

class $$CloudAthleteProfileAssignmentsTableFilterComposer
    extends Composer<_$AppDb, $CloudAthleteProfileAssignmentsTable> {
  $$CloudAthleteProfileAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get athleteProfileId => $composableBuilder(
      column: $table.athleteProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get canView => $composableBuilder(
      column: $table.canView, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get canEdit => $composableBuilder(
      column: $table.canEdit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$CloudAthleteProfileAssignmentsTableOrderingComposer
    extends Composer<_$AppDb, $CloudAthleteProfileAssignmentsTable> {
  $$CloudAthleteProfileAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get athleteProfileId => $composableBuilder(
      column: $table.athleteProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get canView => $composableBuilder(
      column: $table.canView, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get canEdit => $composableBuilder(
      column: $table.canEdit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$CloudAthleteProfileAssignmentsTableAnnotationComposer
    extends Composer<_$AppDb, $CloudAthleteProfileAssignmentsTable> {
  $$CloudAthleteProfileAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get athleteProfileId => $composableBuilder(
      column: $table.athleteProfileId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get canView =>
      $composableBuilder(column: $table.canView, builder: (column) => column);

  GeneratedColumn<bool> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);
}

class $$CloudAthleteProfileAssignmentsTableTableManager
    extends RootTableManager<
        _$AppDb,
        $CloudAthleteProfileAssignmentsTable,
        CloudAthleteProfileAssignment,
        $$CloudAthleteProfileAssignmentsTableFilterComposer,
        $$CloudAthleteProfileAssignmentsTableOrderingComposer,
        $$CloudAthleteProfileAssignmentsTableAnnotationComposer,
        $$CloudAthleteProfileAssignmentsTableCreateCompanionBuilder,
        $$CloudAthleteProfileAssignmentsTableUpdateCompanionBuilder,
        (
          CloudAthleteProfileAssignment,
          BaseReferences<_$AppDb, $CloudAthleteProfileAssignmentsTable,
              CloudAthleteProfileAssignment>
        ),
        CloudAthleteProfileAssignment,
        PrefetchHooks Function()> {
  $$CloudAthleteProfileAssignmentsTableTableManager(
      _$AppDb db, $CloudAthleteProfileAssignmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudAthleteProfileAssignmentsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudAthleteProfileAssignmentsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudAthleteProfileAssignmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> athleteProfileId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<bool> canView = const Value.absent(),
            Value<bool> canEdit = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudAthleteProfileAssignmentsCompanion(
            id: id,
            workspaceId: workspaceId,
            athleteProfileId: athleteProfileId,
            userId: userId,
            canView: canView,
            canEdit: canEdit,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workspaceId,
            required String athleteProfileId,
            required String userId,
            Value<bool> canView = const Value.absent(),
            Value<bool> canEdit = const Value.absent(),
            required int createdAt,
            required String createdByUserId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudAthleteProfileAssignmentsCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            athleteProfileId: athleteProfileId,
            userId: userId,
            canView: canView,
            canEdit: canEdit,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudAthleteProfileAssignmentsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $CloudAthleteProfileAssignmentsTable,
        CloudAthleteProfileAssignment,
        $$CloudAthleteProfileAssignmentsTableFilterComposer,
        $$CloudAthleteProfileAssignmentsTableOrderingComposer,
        $$CloudAthleteProfileAssignmentsTableAnnotationComposer,
        $$CloudAthleteProfileAssignmentsTableCreateCompanionBuilder,
        $$CloudAthleteProfileAssignmentsTableUpdateCompanionBuilder,
        (
          CloudAthleteProfileAssignment,
          BaseReferences<_$AppDb, $CloudAthleteProfileAssignmentsTable,
              CloudAthleteProfileAssignment>
        ),
        CloudAthleteProfileAssignment,
        PrefetchHooks Function()>;
typedef $$CloudWorkspaceInvitesTableCreateCompanionBuilder
    = CloudWorkspaceInvitesCompanion Function({
  required String id,
  required String workspaceId,
  required String email,
  required String role,
  Value<String?> displayName,
  required int expiresAt,
  required String status,
  required String assignedProfileIdsJson,
  required int createdAt,
  required String createdByUserId,
  Value<int> rowid,
});
typedef $$CloudWorkspaceInvitesTableUpdateCompanionBuilder
    = CloudWorkspaceInvitesCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> email,
  Value<String> role,
  Value<String?> displayName,
  Value<int> expiresAt,
  Value<String> status,
  Value<String> assignedProfileIdsJson,
  Value<int> createdAt,
  Value<String> createdByUserId,
  Value<int> rowid,
});

class $$CloudWorkspaceInvitesTableFilterComposer
    extends Composer<_$AppDb, $CloudWorkspaceInvitesTable> {
  $$CloudWorkspaceInvitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedProfileIdsJson => $composableBuilder(
      column: $table.assignedProfileIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));
}

class $$CloudWorkspaceInvitesTableOrderingComposer
    extends Composer<_$AppDb, $CloudWorkspaceInvitesTable> {
  $$CloudWorkspaceInvitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedProfileIdsJson => $composableBuilder(
      column: $table.assignedProfileIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));
}

class $$CloudWorkspaceInvitesTableAnnotationComposer
    extends Composer<_$AppDb, $CloudWorkspaceInvitesTable> {
  $$CloudWorkspaceInvitesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
      column: $table.workspaceId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get assignedProfileIdsJson => $composableBuilder(
      column: $table.assignedProfileIdsJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);
}

class $$CloudWorkspaceInvitesTableTableManager extends RootTableManager<
    _$AppDb,
    $CloudWorkspaceInvitesTable,
    CloudWorkspaceInvite,
    $$CloudWorkspaceInvitesTableFilterComposer,
    $$CloudWorkspaceInvitesTableOrderingComposer,
    $$CloudWorkspaceInvitesTableAnnotationComposer,
    $$CloudWorkspaceInvitesTableCreateCompanionBuilder,
    $$CloudWorkspaceInvitesTableUpdateCompanionBuilder,
    (
      CloudWorkspaceInvite,
      BaseReferences<_$AppDb, $CloudWorkspaceInvitesTable, CloudWorkspaceInvite>
    ),
    CloudWorkspaceInvite,
    PrefetchHooks Function()> {
  $$CloudWorkspaceInvitesTableTableManager(
      _$AppDb db, $CloudWorkspaceInvitesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudWorkspaceInvitesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudWorkspaceInvitesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudWorkspaceInvitesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workspaceId = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<int> expiresAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> assignedProfileIdsJson = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspaceInvitesCompanion(
            id: id,
            workspaceId: workspaceId,
            email: email,
            role: role,
            displayName: displayName,
            expiresAt: expiresAt,
            status: status,
            assignedProfileIdsJson: assignedProfileIdsJson,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workspaceId,
            required String email,
            required String role,
            Value<String?> displayName = const Value.absent(),
            required int expiresAt,
            required String status,
            required String assignedProfileIdsJson,
            required int createdAt,
            required String createdByUserId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CloudWorkspaceInvitesCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            email: email,
            role: role,
            displayName: displayName,
            expiresAt: expiresAt,
            status: status,
            assignedProfileIdsJson: assignedProfileIdsJson,
            createdAt: createdAt,
            createdByUserId: createdByUserId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CloudWorkspaceInvitesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDb,
        $CloudWorkspaceInvitesTable,
        CloudWorkspaceInvite,
        $$CloudWorkspaceInvitesTableFilterComposer,
        $$CloudWorkspaceInvitesTableOrderingComposer,
        $$CloudWorkspaceInvitesTableAnnotationComposer,
        $$CloudWorkspaceInvitesTableCreateCompanionBuilder,
        $$CloudWorkspaceInvitesTableUpdateCompanionBuilder,
        (
          CloudWorkspaceInvite,
          BaseReferences<_$AppDb, $CloudWorkspaceInvitesTable,
              CloudWorkspaceInvite>
        ),
        CloudWorkspaceInvite,
        PrefetchHooks Function()>;
typedef $$AppContextStateTableCreateCompanionBuilder = AppContextStateCompanion
    Function({
  Value<String> id,
  Value<String?> activeWorkspaceId,
  Value<String?> activeProfileId,
  Value<String?> activeRole,
  Value<String?> lastAuthUserId,
  Value<bool> needsCloudClaim,
  Value<String?> pendingInviteToken,
  Value<int?> updatedAt,
  Value<int> rowid,
});
typedef $$AppContextStateTableUpdateCompanionBuilder = AppContextStateCompanion
    Function({
  Value<String> id,
  Value<String?> activeWorkspaceId,
  Value<String?> activeProfileId,
  Value<String?> activeRole,
  Value<String?> lastAuthUserId,
  Value<bool> needsCloudClaim,
  Value<String?> pendingInviteToken,
  Value<int?> updatedAt,
  Value<int> rowid,
});

class $$AppContextStateTableFilterComposer
    extends Composer<_$AppDb, $AppContextStateTable> {
  $$AppContextStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeWorkspaceId => $composableBuilder(
      column: $table.activeWorkspaceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeProfileId => $composableBuilder(
      column: $table.activeProfileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeRole => $composableBuilder(
      column: $table.activeRole, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAuthUserId => $composableBuilder(
      column: $table.lastAuthUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsCloudClaim => $composableBuilder(
      column: $table.needsCloudClaim,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pendingInviteToken => $composableBuilder(
      column: $table.pendingInviteToken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppContextStateTableOrderingComposer
    extends Composer<_$AppDb, $AppContextStateTable> {
  $$AppContextStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeWorkspaceId => $composableBuilder(
      column: $table.activeWorkspaceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeProfileId => $composableBuilder(
      column: $table.activeProfileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeRole => $composableBuilder(
      column: $table.activeRole, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAuthUserId => $composableBuilder(
      column: $table.lastAuthUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsCloudClaim => $composableBuilder(
      column: $table.needsCloudClaim,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pendingInviteToken => $composableBuilder(
      column: $table.pendingInviteToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppContextStateTableAnnotationComposer
    extends Composer<_$AppDb, $AppContextStateTable> {
  $$AppContextStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activeWorkspaceId => $composableBuilder(
      column: $table.activeWorkspaceId, builder: (column) => column);

  GeneratedColumn<String> get activeProfileId => $composableBuilder(
      column: $table.activeProfileId, builder: (column) => column);

  GeneratedColumn<String> get activeRole => $composableBuilder(
      column: $table.activeRole, builder: (column) => column);

  GeneratedColumn<String> get lastAuthUserId => $composableBuilder(
      column: $table.lastAuthUserId, builder: (column) => column);

  GeneratedColumn<bool> get needsCloudClaim => $composableBuilder(
      column: $table.needsCloudClaim, builder: (column) => column);

  GeneratedColumn<String> get pendingInviteToken => $composableBuilder(
      column: $table.pendingInviteToken, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppContextStateTableTableManager extends RootTableManager<
    _$AppDb,
    $AppContextStateTable,
    AppContextStateData,
    $$AppContextStateTableFilterComposer,
    $$AppContextStateTableOrderingComposer,
    $$AppContextStateTableAnnotationComposer,
    $$AppContextStateTableCreateCompanionBuilder,
    $$AppContextStateTableUpdateCompanionBuilder,
    (
      AppContextStateData,
      BaseReferences<_$AppDb, $AppContextStateTable, AppContextStateData>
    ),
    AppContextStateData,
    PrefetchHooks Function()> {
  $$AppContextStateTableTableManager(_$AppDb db, $AppContextStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppContextStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppContextStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppContextStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> activeWorkspaceId = const Value.absent(),
            Value<String?> activeProfileId = const Value.absent(),
            Value<String?> activeRole = const Value.absent(),
            Value<String?> lastAuthUserId = const Value.absent(),
            Value<bool> needsCloudClaim = const Value.absent(),
            Value<String?> pendingInviteToken = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppContextStateCompanion(
            id: id,
            activeWorkspaceId: activeWorkspaceId,
            activeProfileId: activeProfileId,
            activeRole: activeRole,
            lastAuthUserId: lastAuthUserId,
            needsCloudClaim: needsCloudClaim,
            pendingInviteToken: pendingInviteToken,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> activeWorkspaceId = const Value.absent(),
            Value<String?> activeProfileId = const Value.absent(),
            Value<String?> activeRole = const Value.absent(),
            Value<String?> lastAuthUserId = const Value.absent(),
            Value<bool> needsCloudClaim = const Value.absent(),
            Value<String?> pendingInviteToken = const Value.absent(),
            Value<int?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppContextStateCompanion.insert(
            id: id,
            activeWorkspaceId: activeWorkspaceId,
            activeProfileId: activeProfileId,
            activeRole: activeRole,
            lastAuthUserId: lastAuthUserId,
            needsCloudClaim: needsCloudClaim,
            pendingInviteToken: pendingInviteToken,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppContextStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $AppContextStateTable,
    AppContextStateData,
    $$AppContextStateTableFilterComposer,
    $$AppContextStateTableOrderingComposer,
    $$AppContextStateTableAnnotationComposer,
    $$AppContextStateTableCreateCompanionBuilder,
    $$AppContextStateTableUpdateCompanionBuilder,
    (
      AppContextStateData,
      BaseReferences<_$AppDb, $AppContextStateTable, AppContextStateData>
    ),
    AppContextStateData,
    PrefetchHooks Function()>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db, _db.workoutDays);
  $$ActualStrengthSetsTableTableManager get actualStrengthSets =>
      $$ActualStrengthSetsTableTableManager(_db, _db.actualStrengthSets);
  $$PrescribedStrengthSetsTableTableManager get prescribedStrengthSets =>
      $$PrescribedStrengthSetsTableTableManager(
          _db, _db.prescribedStrengthSets);
  $$AppPromptTemplatesTableTableManager get appPromptTemplates =>
      $$AppPromptTemplatesTableTableManager(_db, _db.appPromptTemplates);
  $$SleepNightsTableTableManager get sleepNights =>
      $$SleepNightsTableTableManager(_db, _db.sleepNights);
  $$RunSessionsTableTableManager get runSessions =>
      $$RunSessionsTableTableManager(_db, _db.runSessions);
  $$RunSegmentsTableTableManager get runSegments =>
      $$RunSegmentsTableTableManager(_db, _db.runSegments);
  $$RunSessionDetailsTableTableManager get runSessionDetails =>
      $$RunSessionDetailsTableTableManager(_db, _db.runSessionDetails);
  $$RunOverrideAuditTableTableManager get runOverrideAudit =>
      $$RunOverrideAuditTableTableManager(_db, _db.runOverrideAudit);
  $$RuleTriggersTableTableManager get ruleTriggers =>
      $$RuleTriggersTableTableManager(_db, _db.ruleTriggers);
  $$AiAuditTableTableManager get aiAudit =>
      $$AiAuditTableTableManager(_db, _db.aiAudit);
  $$ExerciseSubstitutionsTableTableManager get exerciseSubstitutions =>
      $$ExerciseSubstitutionsTableTableManager(_db, _db.exerciseSubstitutions);
  $$PlanCyclesTableTableManager get planCycles =>
      $$PlanCyclesTableTableManager(_db, _db.planCycles);
  $$PlanDaysTableTableManager get planDays =>
      $$PlanDaysTableTableManager(_db, _db.planDays);
  $$PlanExerciseAlternativesTableTableManager get planExerciseAlternatives =>
      $$PlanExerciseAlternativesTableTableManager(
          _db, _db.planExerciseAlternatives);
  $$PlanPrescribedStrengthSetsTableTableManager
      get planPrescribedStrengthSets =>
          $$PlanPrescribedStrengthSetsTableTableManager(
              _db, _db.planPrescribedStrengthSets);
  $$PlanPrescribedRunsTableTableManager get planPrescribedRuns =>
      $$PlanPrescribedRunsTableTableManager(_db, _db.planPrescribedRuns);
  $$PlanLongRangeWeeksTableTableManager get planLongRangeWeeks =>
      $$PlanLongRangeWeeksTableTableManager(_db, _db.planLongRangeWeeks);
  $$PlanLongRangeWeekPerformanceTableTableManager
      get planLongRangeWeekPerformance =>
          $$PlanLongRangeWeekPerformanceTableTableManager(
              _db, _db.planLongRangeWeekPerformance);
  $$PlanSummarySnapshotsTableTableManager get planSummarySnapshots =>
      $$PlanSummarySnapshotsTableTableManager(_db, _db.planSummarySnapshots);
  $$PlanImportAuditTableTableManager get planImportAudit =>
      $$PlanImportAuditTableTableManager(_db, _db.planImportAudit);
  $$CloudWorkspacesTableTableManager get cloudWorkspaces =>
      $$CloudWorkspacesTableTableManager(_db, _db.cloudWorkspaces);
  $$CloudWorkspaceMembershipsTableTableManager get cloudWorkspaceMemberships =>
      $$CloudWorkspaceMembershipsTableTableManager(
          _db, _db.cloudWorkspaceMemberships);
  $$CloudAthleteProfilesTableTableManager get cloudAthleteProfiles =>
      $$CloudAthleteProfilesTableTableManager(_db, _db.cloudAthleteProfiles);
  $$CloudAthleteProfileAssignmentsTableTableManager
      get cloudAthleteProfileAssignments =>
          $$CloudAthleteProfileAssignmentsTableTableManager(
              _db, _db.cloudAthleteProfileAssignments);
  $$CloudWorkspaceInvitesTableTableManager get cloudWorkspaceInvites =>
      $$CloudWorkspaceInvitesTableTableManager(_db, _db.cloudWorkspaceInvites);
  $$AppContextStateTableTableManager get appContextState =>
      $$AppContextStateTableTableManager(_db, _db.appContextState);
}
