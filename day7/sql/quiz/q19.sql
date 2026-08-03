-- Q19. HR 학과 학생 일부와의 비교 데모 (> ANY: HR 학생 중 한 명보다라도 GPA가 높으면 포함)
SELECT student_id, name, gpa
FROM   student
WHERE  gpa > ANY (SELECT gpa FROM student WHERE major = 'HR')
ORDER BY student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)
