UNIT UTILITIES_TIME;

// This unit 'UTILITIES_TIME' contains some common time and date functions and types which are missing in standard library.
// Please check Git repository for updates from time to time.

INTERFACE
	USES UTILITIES_STRING;
	
	FUNCTION TIME_TO_PARTS;
	FUNCTION TIME_OF_DAY_TO_PARTS;
	FUNCTION DATE_TO_PARTS;
	FUNCTION DATE_AND_TIME_TO_PARTS;
	FUNCTION DAYS_IN_YEAR;
	FUNCTION DAY_OF_WEEK;
	FUNCTION DAY_OF_YEAR;
	FUNCTION WEEK_OF_YEAR;
	FUNCTION DATE_TO_DAY;
	FUNCTION DATE_TO_MONTH;
	FUNCTION DATE_TO_YEAR;
	
	TYPE
		// Contains all parts of a positive duration (days, hours, minutes, seconds, etc.).
		TIME_PARTS : STRUCT
			day : USINT; // numeric day (e.g. 1)
			hour : USINT; // numeric hour (e.g. 21)
			minute : USINT; // numeric minute of hour (e.g. 34)
			second : USINT; // numeric second of minute (e.g. 56)
			millisecond : UINT; // numeric millisecond of second (e.g. 789)
			iso8601 : STRING[18]; // duration in ISO 8601 representation (e.g. 'P1DT21H34M56.789S')
		END_STRUCT
		
		// Contains all parts of a local date (year, month, day, etc.).
		DATE_PARTS : STRUCT
			year : UINT; // numeric year (e.g. 2019)
			year_of_century : USINT; // numeric year of century (e.g. 19)
			month : USINT; // numeric month of year (e.g. 10)
			day : USINT; // numeric day of month (e.g. 31)
			day_of_year : UINT; // numeric day of year (e.g. 304)
			day_of_week : USINT; // numeric day of week (Monday = 1 <-> Sunday = 7; e.g. 4)
			week_of_year : USINT; // numeric week of year (e.g. 44)
			iso8601 : STRING[10]; // date in ISO 8601 representation (e.g. '2019-10-31')
		END_STRUCT
		
		// Contains all parts of a local time (hours, minutes, seconds, etc.).
		TIME_OF_DAY_PARTS : STRUCT
			hour : USINT; // numeric hour of day (e.g. 21)
			minute : USINT; // numeric minute of hour (e.g. 34)
			second : USINT; // numeric second of minute (e.g. 56)
			millisecond : UINT; // numeric millisecond of second (e.g. 789)
			iso8601 : STRING[12]; // time of day in ISO 8601 representation (e.g. '21:34:56.789')
		END_STRUCT
		
		// Contains all parts of a local date (year, month, day, etc.) and time (hours, minutes, seconds, etc.).
		DATE_AND_TIME_PARTS : STRUCT
			year : UINT; // numeric year (e.g. 2019)
			year_of_century : USINT; // numeric year of century (e.g. 19)
			month : USINT; // numeric month of year (e.g. 10)
			day : USINT; // numeric day of month (e.g. 31)
			day_of_year : UINT; // numeric day of year (e.g. 304)
			day_of_week : USINT; // numeric day of week (Monday = 1 <-> Sunday = 7; e.g. 4)
			week_of_year : USINT; // numeric week of year (e.g. 44)
			hour : USINT; // numeric hour of day (e.g. 21)
			minute : USINT; // numeric minute of hour (e.g. 34)
			second : USINT; // numeric second of minute (e.g. 56)
			millisecond : UINT; // numeric millisecond of second (e.g. 789)
			iso8601 : STRING[23]; // date and time in ISO 8601 representation (e.g. '2019-10-31T21:34:56.789')
		END_STRUCT
	END_TYPE
END_INTERFACE


IMPLEMENTATION
	// Converts internal TIME type to TIME_PARTS structure.
	FUNCTION TIME_TO_PARTS : TIME_PARTS
		VAR_INPUT
			in : TIME;
		END_VAR
		
		VAR_TEMP
			milliseconds : UDINT;
			seconds : UDINT;
			minutes : UDINT;
			hours : UDINT;
			days : UDINT;
			out : TIME_PARTS;
		END_VAR
		
		milliseconds := TIME_TO_UDINT(in);
		out.millisecond := UDINT_TO_UINT(milliseconds MOD 1000);
		
		seconds := (milliseconds - out.millisecond) / 1000;
		out.second := UDINT_TO_USINT(seconds MOD 60);
		
		minutes := (seconds - out.second) / 60;
		out.minute := UDINT_TO_USINT(minutes MOD 60);
		
		hours := (minutes - out.minute) / 60;
		out.hour := UDINT_TO_USINT(hours MOD 24);

		days := (hours - out.hour) / 24;
		out.day := UDINT_TO_USINT(days);
		
		out.iso8601 := 'P';
		
		IF out.day <> 0 THEN
			out.iso8601 := CONCAT3(out.iso8601, USINT_TO_STRING(out.day), 'D');
		END_IF;

		out.iso8601 := CONCAT(out.iso8601, 'T');

		IF out.hour <> 0 THEN
			out.iso8601 := CONCAT3(out.iso8601, USINT_TO_STRING(out.hour), 'H');
		END_IF;

		IF out.minute <> 0 THEN
			out.iso8601 := CONCAT3(out.iso8601, USINT_TO_STRING(out.minute), 'M');
		END_IF;

		IF out.second <> 0 OR out.millisecond <> 0 THEN
			out.iso8601 := CONCAT(out.iso8601, USINT_TO_STRING(out.second));
			
			IF out.millisecond >= 100 THEN
				out.iso8601 := CONCAT3(out.iso8601, '.', UINT_TO_STRING(out.millisecond));
			ELSIF out.millisecond >= 10 THEN
				out.iso8601 := CONCAT3(out.iso8601, '.0', UINT_TO_STRING(out.millisecond));
			ELSE
				out.iso8601 := CONCAT3(out.iso8601, '.00', UINT_TO_STRING(out.millisecond));
			END_IF;

			out.iso8601 := CONCAT(out.iso8601, 'S');
		END_IF;

		TIME_TO_PARTS := out;
	END_FUNCTION
	
	// Converts internal TIME_OF_DAY type to TIME_OF_DAY_PARTS structure.
	FUNCTION TIME_OF_DAY_TO_PARTS : TIME_OF_DAY_PARTS
		VAR_INPUT
			in : TIME_OF_DAY;
		END_VAR
		
		VAR_TEMP
			in_array : ARRAY[0..3] OF BYTE; // Array for marshalling
			milliseconds : UDINT;
			seconds : UDINT;
			minutes : UDINT;
			hours : UDINT;
			out : TIME_OF_DAY_PARTS;
		END_VAR
		
		in_array := ANYTYPE_TO_LITTLEBYTEARRAY(in, 0);
		milliseconds := LITTLEBYTEARRAY_TO_ANYTYPE(in_array, 0);
		out.millisecond := UDINT_TO_UINT(milliseconds MOD 1000);
		
		seconds := (milliseconds - out.millisecond) / 1000;
		out.second := UDINT_TO_USINT(seconds MOD 60);
		
		minutes := (seconds - out.second) / 60;
		out.minute := UDINT_TO_USINT(minutes MOD 60);
		
		hours := (minutes - out.minute) / 60;
		out.hour := UDINT_TO_USINT(hours MOD 24);
		
		IF out.hour >= 10 THEN
			out.iso8601 := CONCAT(USINT_TO_STRING(out.hour), ':');
		ELSE
			out.iso8601 := CONCAT3('0', USINT_TO_STRING(out.hour), ':');
		END_IF;
		
		IF out.minute >= 10 THEN
			out.iso8601 := CONCAT3(out.iso8601, USINT_TO_STRING(out.minute), ':');
		ELSE
			out.iso8601 := CONCAT4(out.iso8601, '0', USINT_TO_STRING(out.minute), ':');
		END_IF;
		
		IF out.second >= 10 THEN
			out.iso8601 := CONCAT3(out.iso8601, USINT_TO_STRING(out.second), '.');
		ELSE
			out.iso8601 := CONCAT4(out.iso8601, '0', USINT_TO_STRING(out.second), '.');
		END_IF;
		
		IF out.millisecond >= 100 THEN
			out.iso8601 := CONCAT(out.iso8601, UINT_TO_STRING(out.millisecond));
		ELSIF out.millisecond >= 10 THEN
			out.iso8601 := CONCAT3(out.iso8601, '0', UINT_TO_STRING(out.millisecond));
		ELSE
			out.iso8601 := CONCAT3(out.iso8601, '00', UINT_TO_STRING(out.millisecond));
		END_IF;

		TIME_OF_DAY_TO_PARTS := out;
	END_FUNCTION
	
	// Converts internal DATE type to DATE_PARTS structure.
	FUNCTION DATE_TO_PARTS : DATE_PARTS
		VAR_INPUT
			in: DATE;
			fd: BOOL; (* TRUE - first day Monday, FALSE - first day Sunday *)
		END_VAR
		
		out.year  := DATE_TO_YEAR(in);
		out.month := DATE_TO_MONTH(in);
		out.day   := DATE_TO_DAY(in);
		
		out.year_of_century := UINT_TO_USINT(out.year MOD 100);
		out.day_of_year     := DAY_OF_YEAR(out.year, out.day);
		out.day_of_week     := DAY_OF_WEEK(in, fd);
		out.week_of_year    := WEEK_OF_YEAR(in, fd);
		
		out.iso8601 := MID(DATE_TO_STRING(in), 3, 10);
		
		DATE_TO_PARTS := out;
	END_FUNCTION
	
	// Converts internal DATE_AND_TIME type to DATE_AND_TIME_PARTS structure.
	FUNCTION DATE_AND_TIME_TO_PARTS : DATE_AND_TIME_PARTS
		VAR_INPUT
			in : DATE_AND_TIME;
		END_VAR
		
		VAR_TEMP
			dat_parts : DATE_PARTS;
			tod_parts : TIME_OF_DAY_PARTS;
			out : DATE_AND_TIME_PARTS;
		END_VAR
		
		dat_parts := DATE_TO_PARTS(DT_TO_DATE(in));
		tod_parts := TIME_OF_DAY_TO_PARTS(DT_TO_TOD(in));
		
		out.year := dat_parts.year;
		out.year_of_century := dat_parts.year_of_century;
		out.month := dat_parts.month;
		out.day := dat_parts.day;
		out.day_of_year := dat_parts.day_of_year;
		out.day_of_week := dat_parts.day_of_week;
		out.week_of_year := dat_parts.week_of_year;
		
		out.hour := tod_parts.hour;
		out.minute := tod_parts.minute;
		out.second := tod_parts.second;
		out.millisecond := tod_parts.millisecond;
		
		out.iso8601 := CONCAT3(dat_parts.iso8601, 'T', tod_parts.iso8601);
		
		DATE_AND_TIME_TO_PARTS := out;
	END_FUNCTION

	FUNCTION DAYS_IN_YEAR : UINT
		VAR_INPUT
			year: UINT; (* Given year *)
		END_VAR
		
		IF year MOD 4 = 0 AND (year = 2000 OR year MOD 100 <> 0) THEN
			DAYS_IN_YEAR := 366;
		ELSE
			DAYS_IN_YEAR := 365;
		END_IF;
	END_FUNCTION

	FUNCTION DAY_OF_WEEK : USINT
		VAR_INPUT
			cur_date: DATE; (* Current date *)
			fd:       BOOL; (* TRUE - first day Monday, FALSE - first day Sunday *)
		END_VAR
		VAR
			correction : UINT := 4;
		END_VAR

		IF fd THEN
			correction := 3;
		END_IF;

		DAY_OF_WEEK := DWORD_TO_USINT(((DATE_TO_DWORD(cur_date) / 86400) + correction) MOD 7);
	END_FUNCTION

	FUNCTION DAY_OF_YEAR : UINT
		VAR_INPUT
			month: UINT; (* Current month *)
			day:   USINT; (* Current day *)
		END_VAR
		VAR
			months_days: ARRAY[1..12] OF USINT := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
			i: USINT;
		END_VAR

		FOR i := 1 TO 12 DO
			IF i >= month THEN
				EXIT;
			END_IF;

			IF i <> 2 THEN
				DAY_OF_YEAR := DAY_OF_YEAR + months_days[i];
			ELSE
				IF DAYS_IN_YEAR() > 365 THEN
					DAY_OF_YEAR := DAY_OF_YEAR + 29;
				ELSE
					DAY_OF_YEAR := DAY_OF_YEAR + 28;
				END_IF;
			END_IF;
		END_FOR;

		DAY_OF_YEAR := DAY_OF_YEAR + day;
	END_FUNCTION

	FUNCTION WEEK_OF_YEAR : USINT
		VAR_INPUT
			cur_date: DATE; (* Current date *);
			fd:       BOOL; (* TRUE - first day Monday, FALSE - first day Sunday *)
		END_VAR
		VAR
			Variable: BOOL; (* Comment *)
		END_VAR

		WEEK_OF_YEAR := ((DAY_OF_YEAR(cur_date) + 6) / 7);
		IF 
			DAY_OF_WEEK(cur_date, fd) < 
			DAY_OF_WEEK(STRING_TO_DATE(CONCAT3('D#', DATE_TO_YEAR(cur_date),'-01-01')), fd) 
		THEN
			WEEK_OF_YEAR := WEEK_OF_YEAR + 1;
		END_IF;
	END_FUNCTION

	FUNCTION DATE_TO_YEAR : UINT
		VAR_INPUT
			cur_date: DATE; (* Current date *);
		END_VAR
		VAR_TEMP
			str: STRING[25]; (* Temp strint *)
		END_VAR

		str := DATE_TO_STRING(cur_date); // convert to `D#2000-12-30`
		DATE_TO_YEAR := STRING_TO_UINT(MID(str, 3, 4));
	END_FUNCTION
	
	FUNCTION DATE_TO_MONTH : USINT
		VAR_INPUT
			cur_date: DATE; (* Current date *);
		END_VAR
		VAR_TEMP
			str: STRING[25]; (* Temp strint *)
		END_VAR

		str := DATE_TO_STRING(cur_date); // convert to `D#2000-12-30`
		DATE_TO_MONTH := STRING_TO_USINT(MID(str, 8, 2));
	END_FUNCTION

	FUNCTION DATE_TO_DAY : USINT
		VAR_INPUT
			cur_date: DATE; (* Current date *);
		END_VAR
		VAR_TEMP
			str: STRING[25]; (* Temp strint *)
		END_VAR

		str := DATE_TO_STRING(cur_date); // convert to `D#2000-12-30`
		DATE_TO_DAY := STRING_TO_USINT(MID(str, 11, 2));
	END_FUNCTION
END_IMPLEMENTATION
