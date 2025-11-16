# SQL Assignment — Healthcare Dataset

This repository contains solutions to the SQL assignment using the healthcare dataset. It includes:
- `functions.sql`       -(Q1–Q19)
- `ctes.sql`            -(Q4, Q5, Q6, Q13)
- `stored_procedures.sql` - stored procedures/functions required for Q20 and Q21
- This README with usage instructions.

## Notes & assumptions
- Table and column names use **lowercase snake_case** (e.g., `patients`, `appointments`, `treatment_id`).
- Assumed typical columns:
  - `patients(patient_id, first_name, last_name, gender, date_of_birth, phone, email, address)`
  - `doctors(doctor_id, first_name, last_name, specialization, email, phone)`
  - `appointments(appointment_id, patient_id, doctor_id, appointment_date, status, nurse_id)`
  - `treatments(treatment_id, appointment_id, treatment_type, outcome)`
  - `bills(bill_id, patient_id, total_amount, is_paid)`
  - `payments(payment_id, bill_id, amount, payment_date)`
  - `admissions(admission_id, patient_id, ward_id, admission_date, discharge_date, balance_due)`
  - `prescriptions(prescription_id, appointment_id, medication, dosage)`

## How to run
1. Import CSV files into PostgreSQL using DBeaver.
2. Run `functions.sql`, `ctes.sql`, and `stored_procedures.sql` in psql/DBeaver (order: `functions.sql` then `ctes.sql` then `stored_procedures.sql`).
3. Test stored procedures using the example calls as included in `stored_procedures.sql`.
