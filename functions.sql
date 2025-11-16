-- functions.sql
-- 1. All male patients born after 1990
SELECT patient_id, first_name, last_name, date_of_birth
FROM patients
WHERE gender ILIKE 'male'
  AND date_of_birth > DATE '1990-12-31'
ORDER BY date_of_birth;

-- 2. Ten most recent appointments (newest -> oldest)
SELECT appointment_id, patient_id, doctor_id, appointment_date, status
FROM appointments
ORDER BY appointment_date DESC
LIMIT 10;

-- 3. Appointments with full names of patients and doctors
SELECT a.appointment_id,
       a.appointment_date,
       a.status,
       p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d  ON a.doctor_id  = d.doctor_id
ORDER BY a.appointment_date DESC;

-- 4. All patients with treatments (include patients without treatments)
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       t.treatment_id,
       t.treatment_type,
       t.outcome
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
LEFT JOIN treatments t   ON t.appointment_id = a.appointment_id
ORDER BY p.patient_id, t.treatment_id;

-- 5. Treatments that do NOT have a matching appointment
SELECT t.*
FROM treatments t
LEFT JOIN appointments a ON t.appointment_id = a.appointment_id
WHERE a.appointment_id IS NULL;

-- 6. Number of appointments each doctor has handled (highest -> lowest)
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, doctor_name
ORDER BY appointment_count DESC;

-- 7. Doctors who have handled more than 20 appointments
SELECT d.doctor_id,
       d.specialization,
       COUNT(a.appointment_id) AS appointment_count
FROM doctors d
JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.specialization
HAVING COUNT(a.appointment_id) > 20
ORDER BY appointment_count DESC;

-- 8. Details of patients who had appointments with Cardiology doctors
SELECT DISTINCT p.*
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE d.specialization ILIKE 'cardiology';

-- 9. Patients who have at least one unpaid bill
-- assumes bills.is_paid is boolean (FALSE for unpaid). If column is named differently (e.g. paid, payment_status), replace.
SELECT DISTINCT p.patient_id, p.first_name, p.last_name, b.bill_id, b.total_amount
FROM patients p
JOIN bills b ON p.patient_id = b.patient_id
WHERE COALESCE(b.is_paid, FALSE) = FALSE;

-- 10. Bills whose total_amount is higher than the average bill amount
SELECT *
FROM bills
WHERE total_amount > (SELECT AVG(total_amount) FROM bills);

-- 11. Most recent appointment for each patient (patient_id + appointment_id + appointment_date)
-- Using DISTINCT ON (Postgres)
SELECT DISTINCT ON (a.patient_id)
       a.patient_id,
       a.appointment_id,
       a.appointment_date
FROM appointments a
ORDER BY a.patient_id, a.appointment_date DESC;

-- 12. For every appointment, assign sequence number ranking each patient's appointments from most recent to oldest
SELECT a.*,
       ROW_NUMBER() OVER (PARTITION BY a.patient_id ORDER BY a.appointment_date DESC) AS appt_rank
FROM appointments a
ORDER BY a.patient_id, appt_rank;

-- 13. Number of appointments per day for October 2021, with running total across the month
WITH daily AS (
  SELECT date_trunc('day', appointment_date)::date AS day,
         COUNT(*) AS appointments_on_day
  FROM appointments
  WHERE appointment_date >= DATE '2021-10-01'
    AND appointment_date <  DATE '2021-11-01'
  GROUP BY day
)
SELECT day,
       appointments_on_day,
       SUM(appointments_on_day) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM daily
ORDER BY day;

-- 14. Temporary query: average, minimum, maximum total bill amount in a single result set
WITH bill_stats AS (
  SELECT
    AVG(total_amount)::numeric(12,2) AS avg_total_amount,
    MIN(total_amount)           AS min_total_amount,
    MAX(total_amount)           AS max_total_amount
  FROM bills
)
SELECT * FROM bill_stats;

-- Sum payments per bill
WITH payments_per_bill AS (
  SELECT bill_id, SUM(amount) AS paid_amount
  FROM payments
  GROUP BY bill_id
),
bill_balances AS (
  SELECT b.bill_id,
         b.patient_id,
         b.total_amount,
         COALESCE(p.paid_amount, 0) AS paid_amount,
         (b.total_amount - COALESCE(p.paid_amount, 0)) AS balance_due
  FROM bills b
  LEFT JOIN payments_per_bill p ON b.bill_id = p.bill_id
),
patients_with_outstanding AS (
  SELECT DISTINCT patient_id
  FROM (
    SELECT patient_id FROM admissions WHERE COALESCE(balance_due, 0) > 0
    UNION
    SELECT patient_id FROM bill_balances WHERE (total_amount - paid_amount) > 0
  ) x
)
SELECT p.*
FROM patients p
JOIN patients_with_outstanding pow ON p.patient_id = pow.patient_id;

-- 16. Generate dates from 2021-01-01 to 2021-01-15 and show how many appointments occurred on each date
SELECT gs.day::date AS day,
       COALESCE(count(a.appointment_id), 0) AS appointments_count
FROM generate_series('2021-01-01'::date, '2021-01-15'::date, '1 day') AS gs(day)
LEFT JOIN appointments a ON a.appointment_date::date = gs.day::date
GROUP BY gs.day
ORDER BY gs.day;

-- 17. Add a new patient record (sample INSERT)
INSERT INTO patients (
  patient_id, first_name, last_name, gender, date_of_birth, phone, email, address
) VALUES (
  'pat_1001', 'Jane', 'Doe', 'Female', '1995-04-21', '+254700000001', 'jane.doe@example.com', '123 Example Ave'
);

-- 18. Update appointments so any NULL status becomes 'Scheduled'
UPDATE appointments
SET status = 'Scheduled'
WHERE status IS NULL;

-- 19. Remove all prescription records that belong to appointments marked as 'Cancelled'
DELETE FROM prescriptions p
WHERE p.appointment_id IN (
  SELECT a.appointment_id
  FROM appointments a
  WHERE a.status ILIKE 'cancelled'
);
