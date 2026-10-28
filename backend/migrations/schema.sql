-- =============================================================================
-- HMSS Database Schema
-- Hospital Management Software System
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- USER
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user` (
    `user_id`       INT AUTO_INCREMENT PRIMARY KEY,
    `role`          VARCHAR(20) NOT NULL COMMENT 'patient, doctor, or secretary',
    `first_name`    VARCHAR(50) NOT NULL,
    `last_name`     VARCHAR(50) NOT NULL,
    `email`         VARCHAR(100) UNIQUE NOT NULL,
    `phone`         VARCHAR(20),
    `password_hash` VARCHAR(255) NOT NULL,
    `is_active`     BOOLEAN DEFAULT TRUE,
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- PATIENT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient` (
    `patient_id`              INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`                 INT NOT NULL,
    `patient_code`            VARCHAR(30) UNIQUE,
    `national_id`             VARCHAR(30) UNIQUE,
    `date_of_birth`           DATE,
    `gender`                  VARCHAR(10),
    `address`                 TEXT,
    `blood_type`              VARCHAR(5),
    `allergies`               TEXT,
    `chronic_conditions`      TEXT,
    `insurance_provider`      VARCHAR(100),
    `insurance_number`        VARCHAR(50),
    `emergency_contact_name`  VARCHAR(100),
    `emergency_contact_phone` VARCHAR(20),
    `created_at`              DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_patient_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- DOCTOR
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `doctor` (
    `doctor_id`      INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NOT NULL,
    `specialization` VARCHAR(100),
    `license_number` VARCHAR(50) UNIQUE,
    `office_room`    VARCHAR(20),
    `created_at`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_doctor_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- SECRETARY
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `secretary` (
    `secretary_id`  INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`       INT NOT NULL,
    `employee_code` VARCHAR(30) UNIQUE,
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_secretary_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- PATIENT_DOCTOR_ASSIGNMENT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient_doctor_assignment` (
    `assignment_id`      INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id`         INT NOT NULL,
    `doctor_id`          INT NOT NULL,
    `created_by_user_id` INT NOT NULL,
    `assigned_at`        DATETIME DEFAULT CURRENT_TIMESTAMP,
    `start_date`         DATE,
    `end_date`           DATE,
    `is_active`          BOOLEAN DEFAULT TRUE,
    `assignment_note`    TEXT,
    CONSTRAINT `fk_pda_patient`  FOREIGN KEY (`patient_id`)         REFERENCES `patient`(`patient_id`),
    CONSTRAINT `fk_pda_doctor`   FOREIGN KEY (`doctor_id`)          REFERENCES `doctor`(`doctor_id`),
    CONSTRAINT `fk_pda_creator`  FOREIGN KEY (`created_by_user_id`) REFERENCES `user`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- APPOINTMENT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `appointment` (
    `appointment_id`          INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id`              INT NOT NULL,
    `doctor_id`               INT NOT NULL,
    `created_by_user_id`      INT NOT NULL,
    `created_by_role`         VARCHAR(20),
    `managed_by_secretary_id` INT,
    `requested_at`            DATETIME DEFAULT CURRENT_TIMESTAMP,
    `scheduled_start`         DATETIME,
    `scheduled_end`           DATETIME,
    `status`                  VARCHAR(30) DEFAULT 'pending'
                              COMMENT 'pending, confirmed, rescheduled, cancelled, completed',
    `reason`                  TEXT,
    `location`                VARCHAR(100),
    `secretary_comment`       TEXT,
    `updated_at`              DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_appt_patient`    FOREIGN KEY (`patient_id`)              REFERENCES `patient`(`patient_id`),
    CONSTRAINT `fk_appt_doctor`     FOREIGN KEY (`doctor_id`)               REFERENCES `doctor`(`doctor_id`),
    CONSTRAINT `fk_appt_creator`    FOREIGN KEY (`created_by_user_id`)      REFERENCES `user`(`user_id`),
    CONSTRAINT `fk_appt_secretary`  FOREIGN KEY (`managed_by_secretary_id`) REFERENCES `secretary`(`secretary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- MEDICAL_TEST
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `medical_test` (
    `test_id`      INT AUTO_INCREMENT PRIMARY KEY,
    `test_code`    VARCHAR(30) UNIQUE NOT NULL,
    `test_name`    VARCHAR(100) NOT NULL,
    `default_unit` VARCHAR(30),
    `description`  TEXT,
    `category`     VARCHAR(50),
    `is_active`    BOOLEAN DEFAULT TRUE,
    `created_at`   DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- TEST_NORMAL_RANGE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `test_normal_range` (
    `range_id`       INT AUTO_INCREMENT PRIMARY KEY,
    `test_id`        INT NOT NULL,
    `population`     VARCHAR(50),
    `sex`            VARCHAR(10),
    `min_age_years`  DECIMAL(5,2),
    `max_age_years`  DECIMAL(5,2),
    `fasting_state`  VARCHAR(20),
    `min_value`      DECIMAL(12,4),
    `max_value`      DECIMAL(12,4),
    `unit`           VARCHAR(30),
    `range_note`     TEXT,
    `effective_from` DATETIME,
    `effective_to`   DATETIME,
    `created_at`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_tnr_test` FOREIGN KEY (`test_id`) REFERENCES `medical_test`(`test_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- TEST_RESULT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `test_result` (
    `result_id`            INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id`           INT NOT NULL,
    `doctor_id`            INT NOT NULL,
    `test_id`              INT NOT NULL,
    `secretary_id`         INT,
    `applied_range_id`     INT,
    `validated_by_user_id` INT,
    `result_date`          DATETIME,
    `value`                DECIMAL(12,4),
    `unit`                 VARCHAR(30),
    `fasting_state`        VARCHAR(20),
    `status`               VARCHAR(30) DEFAULT 'pending',
    `is_flagged`           BOOLEAN DEFAULT FALSE,
    `validation_method`    VARCHAR(50),
    `validated_at`         DATETIME,
    `validation_note`      TEXT,
    `notes`                TEXT,
    `created_at`           DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_tr_patient`   FOREIGN KEY (`patient_id`)           REFERENCES `patient`(`patient_id`),
    CONSTRAINT `fk_tr_doctor`    FOREIGN KEY (`doctor_id`)            REFERENCES `doctor`(`doctor_id`),
    CONSTRAINT `fk_tr_test`      FOREIGN KEY (`test_id`)              REFERENCES `medical_test`(`test_id`),
    CONSTRAINT `fk_tr_secretary` FOREIGN KEY (`secretary_id`)         REFERENCES `secretary`(`secretary_id`),
    CONSTRAINT `fk_tr_range`     FOREIGN KEY (`applied_range_id`)     REFERENCES `test_normal_range`(`range_id`),
    CONSTRAINT `fk_tr_validator` FOREIGN KEY (`validated_by_user_id`) REFERENCES `user`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- NOTIFICATION
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notification` (
    `notification_id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`         INT NOT NULL,
    `type`            VARCHAR(50),
    `title`           VARCHAR(150),
    `message`         TEXT,
    `is_read`         BOOLEAN DEFAULT FALSE,
    `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP,
    `read_at`         DATETIME,
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- AUDIT_LOG
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_log` (
    `audit_id`      INT AUTO_INCREMENT PRIMARY KEY,
    `actor_user_id` INT,
    `action`        VARCHAR(100) NOT NULL,
    `entity_type`   VARCHAR(50),
    `entity_id`     INT,
    `ip_address`    VARCHAR(45),
    `details`       TEXT,
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `user`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- CHATBOT_FAQ_ENTRY
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chatbot_faq_entry` (
    `faq_id`     INT AUTO_INCREMENT PRIMARY KEY,
    `test_id`    INT,
    `topic`      VARCHAR(100),
    `question`   TEXT NOT NULL,
    `answer`     TEXT NOT NULL,
    `is_active`  BOOLEAN DEFAULT TRUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_faq_test` FOREIGN KEY (`test_id`) REFERENCES `medical_test`(`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- CHAT_QUERY_LOG
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat_query_log` (
    `chat_log_id`   INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`       INT,
    `test_id`       INT,
    `faq_id`        INT,
    `query_text`    TEXT,
    `response_text` TEXT,
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_cql_user`  FOREIGN KEY (`user_id`)  REFERENCES `user`(`user_id`),
    CONSTRAINT `fk_cql_test`  FOREIGN KEY (`test_id`)  REFERENCES `medical_test`(`test_id`),
    CONSTRAINT `fk_cql_faq`   FOREIGN KEY (`faq_id`)   REFERENCES `chatbot_faq_entry`(`faq_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- PATIENT_MEDICAL_RESULT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient_medical_result` (
    `result_id`            INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id`           INT NOT NULL,
    `test_id`              INT NOT NULL,
    `value`                VARCHAR(50) NOT NULL,
    `unit`                 VARCHAR(30),
    `status`               VARCHAR(20) DEFAULT 'normal',
    `created_by_user_id`   INT,
    `batch_id`             INT,
    `created_at`           DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_pmr_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient`(`patient_id`),
    CONSTRAINT `fk_pmr_test`    FOREIGN KEY (`test_id`)    REFERENCES `medical_test`(`test_id`),
    CONSTRAINT `fk_pmr_creator` FOREIGN KEY (`created_by_user_id`) REFERENCES `user`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
