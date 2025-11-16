-- ctes.sql

-- Q4 (CTE) Patients with treatments (ensures patients without treatments appear)
WITH patient_appointments AS (
  SELECT p.patient_id, a.appointment_id
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.patient_id
)
SELECT pa.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       t.treatment_id,
       t.treatment_type
FROM patient_appointments pa
JOIN patients p ON p.patient_id = pa.patient_id
LEFT JOIN treatments t ON t.appointment_id = pa.appointment_id
ORDER BY pa.patient_id;

-- Q5 (CTE) Treatments missing appointments
WITH invalid_treatments AS (
  SELECT t.*
  FROM treatments t
  LEFT JOIN appointments a ON t.appointment_id = a.appointment_id
  WHERE a.appointment_id IS NULL
)
SELECT * FROM invalid_treatments;

-- Q6 (CTE) Doctor appointment counts
WITH doctor_counts AS (
  SELECT doctor_id, COUNT(*) AS appt_count
  FROM appointments
  GROUP BY doctor_id
)
SELECT d.doctor_id, d.first_name || ' ' || d.last_name AS doctor_name, dc.appt_count
FROM doctor_counts dc
JOIN doctors d ON d.doctor_id = dc.doctor_id
ORDER BY dc.appt_count DESC;

-- Q13 (CTE) Appointments per day with running total (already in functions.sql, but tidy CTE here)
WITH daily AS (
  SELECT date_trunc('day', appointment_date)::date AS day, COUNT(*) AS appts
  FROM appointments
  WHERE appointment_date BETWEEN '2021-10-01' AND '2021-10-31 23:59:59'
  GROUP BY day
)
SELECT day, appts,
       SUM(appts) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM daily
ORDER BY day;
