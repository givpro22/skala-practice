-- ============================================================
-- 8. 종합실습 - 1 : 학사관리시스템 DB 설계 → 구축 → 조회
-- 02. 스키마 및 테이블 생성 (DDL, 제약조건 포함)
-- 실행: psql skala_edu -f sql/02_ddl_tables.sql
-- ============================================================

-- 학사관리시스템 전용 스키마
CREATE SCHEMA IF NOT EXISTS academy;

SET search_path TO academy;

-- 재실행 대비 초기화 (FK 역순 삭제)
DROP TABLE IF EXISTS enroll;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS professor;
DROP TABLE IF EXISTS department;

-- ------------------------------------------------------------
-- 1) 학과 (department)
-- ------------------------------------------------------------
CREATE TABLE department (
    dept_id          SERIAL       PRIMARY KEY,                 -- 학과 ID
    dept_name        VARCHAR(50)  NOT NULL UNIQUE,             -- 학과명 (중복 불가)
    office           VARCHAR(50),                              -- 학과 사무실 위치
    established_date DATE         NOT NULL                     -- 설립일
);

COMMENT ON TABLE department IS '학과 정보';

-- ------------------------------------------------------------
-- 2) 교수 (professor)  :  department 1 : N professor
-- ------------------------------------------------------------
CREATE TABLE professor (
    prof_id    SERIAL       PRIMARY KEY,                       -- 교수 ID
    prof_name  VARCHAR(30)  NOT NULL,                          -- 교수명
    dept_id    INT          NOT NULL                           -- 소속 학과 (FK)
               REFERENCES department(dept_id),
    position   VARCHAR(20)  NOT NULL                           -- 직급 제약
               CHECK (position IN ('교수', '부교수', '조교수')),
    email      VARCHAR(100) NOT NULL UNIQUE,                   -- 이메일 (중복 불가)
    hire_date  DATE         NOT NULL                           -- 임용일
);

COMMENT ON TABLE professor IS '교수 정보';

-- ------------------------------------------------------------
-- 3) 학생 (student)  :  department 1 : N student
-- ------------------------------------------------------------
CREATE TABLE student (
    student_id     SERIAL       PRIMARY KEY,                   -- 학번
    student_name   VARCHAR(30)  NOT NULL,                      -- 학생명
    dept_id        INT          NOT NULL                       -- 소속 학과 (FK)
                   REFERENCES department(dept_id),
    grade          INT          NOT NULL                       -- 학년 (1~4)
                   CHECK (grade BETWEEN 1 AND 4),
    email          VARCHAR(100) NOT NULL UNIQUE,               -- 이메일 (중복 불가)
    phone          VARCHAR(20),                                -- 연락처 (NULL 허용 → COALESCE 실습)
    birth_date     DATE         NOT NULL,                      -- 생년월일
    admission_date DATE         NOT NULL,                      -- 입학일
    status         VARCHAR(10)  NOT NULL DEFAULT '재학'        -- 학적 상태 제약
                   CHECK (status IN ('재학', '휴학', '졸업'))
);

COMMENT ON TABLE student IS '학생 정보';

-- ------------------------------------------------------------
-- 4) 과목 (course)  :  department 1 : N course, professor 1 : N course
-- ------------------------------------------------------------
CREATE TABLE course (
    course_id   SERIAL      PRIMARY KEY,                       -- 과목 ID
    course_name VARCHAR(60) NOT NULL,                          -- 과목명
    dept_id     INT         NOT NULL                           -- 개설 학과 (FK)
                REFERENCES department(dept_id),
    prof_id     INT         NOT NULL                           -- 담당 교수 (FK)
                REFERENCES professor(prof_id),
    credits     INT         NOT NULL                           -- 학점 (1~3)
                CHECK (credits BETWEEN 1 AND 3),
    semester    VARCHAR(10) NOT NULL,                          -- 개설 학기 (예: 2026-1)
    capacity    INT         NOT NULL DEFAULT 30                -- 수강 정원
                CHECK (capacity > 0)
);

COMMENT ON TABLE course IS '개설 과목 정보';

-- ------------------------------------------------------------
-- 5) 수강신청 (enroll)  :  student N : M course 교차(연결) 테이블
-- ------------------------------------------------------------
CREATE TABLE enroll (
    enroll_id   SERIAL  PRIMARY KEY,                           -- 수강신청 ID
    student_id  INT     NOT NULL                               -- 학생 (FK, 학생 삭제 시 함께 삭제)
                REFERENCES student(student_id) ON DELETE CASCADE,
    course_id   INT     NOT NULL                               -- 과목 (FK)
                REFERENCES course(course_id),
    enroll_date DATE    NOT NULL DEFAULT CURRENT_DATE,         -- 수강신청일
    score       NUMERIC(5,2)                                   -- 성적 (NULL = 미평가 → COALESCE/CASE 실습)
                CHECK (score IS NULL OR score BETWEEN 0 AND 100),
    UNIQUE (student_id, course_id)                             -- 동일 과목 중복 신청 방지
);

COMMENT ON TABLE enroll IS '수강신청 (student-course 교차 테이블)';

-- 생성 결과 확인
\dt academy.*
