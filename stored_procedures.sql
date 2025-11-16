-- stored_procedures.sql

-- 20. Procedure to add a doctor
-- Used a FUNCTION that returns void and inserts into doctors.
CREATE OR REPLACE FUNCTION add_doctor(
  p_doctor_id TEXT,
  p_first_name TEXT,
  p_last_name TEXT,
  p_specialization TEXT,
  p_email TEXT,
  p_phone TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone)
  VALUES (p_doctor_id, p_first_name, p_last_name, p_specialization, p_email, p_phone);
EXCEPTION WHEN unique_violation THEN
  -- If doctor_id is primary key and already exists, raise an error
  RAISE NOTICE 'Doctor with id % already exists. Skipping insert.', p_doctor_id;
END;
$$;

-- Example call to add a doctor (sample data)
SELECT add_doctor('doc_1002', 'Alice', 'Wanjiru', 'Cardiology', 'alice.wanjiru@example.com', '+254700000003');

-- 21. Procedure to record a new appointment with validation
CREATE OR REPLACE FUNCTION record_appointment(
  p_appointment_id TEXT,
  p_patient_id     TEXT,
  p_doctor_id      TEXT,
  p_appointment_date TIMESTAMP,
  p_status         TEXT,
  p_nurse_id       TEXT
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  v_patient_exists INTEGER;
  v_doctor_exists  INTEGER;
BEGIN
  -- Verify patient exists
  SELECT 1 INTO v_patient_exists FROM patients WHERE patient_id = p_patient_id LIMIT 1;
  -- Verify doctor exists
  SELECT 1 INTO v_doctor_exists FROM doctors  WHERE doctor_id  = p_doctor_id  LIMIT 1;

  IF v_patient_exists IS NULL THEN
    RETURN format('ERROR: Patient % does not exist. Appointment not inserted.', p_patient_id);
  ELSIF v_doctor_exists IS NULL THEN
    RETURN format('ERROR: Doctor % does not exist. Appointment not inserted.', p_doctor_id);
  ELSE
    INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, status, nurse_id)
    VALUES (p_appointment_id, p_patient_id, p_doctor_id, p_appointment_date, p_status, p_nurse_id);
    RETURN format('OK: Appointment % inserted for patient % with doctor % on %', p_appointment_id, p_patient_id, p_doctor_id, p_appointment_date);
  END IF;
EXCEPTION WHEN unique_violation THEN
  RETURN format('ERROR: Appointment id % already exists.', p_appointment_id);
END;
$$;

-- Example successful call (assuming patient 'pat_1001' and doctor 'doc_1002' exist)
SELECT record_appointment('appt_2001', 'pat_1001', 'doc_1002', '2025-11-20 10:30:00'::timestamp, 'Scheduled', NULL);

-- Example failed call (non-existent patient or doctor)
-- Attempt using non-existent doctor:
SELECT record_appointment('appt_2002', 'pat_1001', 'nonexistent_doc', '2025-11-21 09:00:00'::timestamp, 'Scheduled', NULL);
