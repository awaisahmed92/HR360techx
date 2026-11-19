-- Demo seeds for Recruitment + Calendar parity
USE `hr360_demo`;

INSERT INTO `hr_recruit_requisitions` (
  `type_id`, `job_title`, `job_type`, `vacancies`, `description`, `status`, `opening_date`, `created_at`
)
SELECT t.id, 'Senior Flutter Developer', 'Permanent', 2, 'Build HR360 Flutter SPA features', 2, CURDATE(), NOW()
FROM `hr_recruit_requisition_types` t
WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_requisitions` WHERE `job_title` = 'Senior Flutter Developer' LIMIT 1)
LIMIT 1;

INSERT INTO `hr_recruit_posts` (
  `requisition_id`, `title`, `job_type`, `vacancies`, `description`, `publish_portal`, `status`, `opening_date`, `created_at`
)
SELECT r.id, 'Senior Flutter Developer', 'Permanent', 2, r.description, 1, 1, CURDATE(), NOW()
FROM `hr_recruit_requisitions` r
WHERE r.job_title = 'Senior Flutter Developer'
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_posts` WHERE title = 'Senior Flutter Developer' AND requisition_id = r.id LIMIT 1)
LIMIT 1;

INSERT INTO `hr_recruit_posts` (
  `title`, `job_type`, `vacancies`, `description`, `publish_portal`, `status`, `opening_date`, `created_at`
)
SELECT 'HR Business Partner', 'Permanent', 1, 'Partner with business units on people strategy', 1, 1, CURDATE(), NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_posts` WHERE title = 'HR Business Partner' LIMIT 1);

-- Ensure sample candidates exist for applications
INSERT INTO `hr_candidate` (`name`, `email`, `phone`, `status`, `total_experience`, `created_at`)
SELECT 'Sara Ahmed', 'sara.ahmed@example.com', '03001234567', 0, '3 years', NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_candidate` WHERE email = 'sara.ahmed@example.com' LIMIT 1);

INSERT INTO `hr_candidate` (`name`, `email`, `phone`, `status`, `total_experience`, `created_at`)
SELECT 'Bilal Hussain', 'bilal.hussain@example.com', '03007654321', 2, '5 years', NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_candidate` WHERE email = 'bilal.hussain@example.com' LIMIT 1);

INSERT INTO `hr_candidate` (`name`, `email`, `phone`, `status`, `total_experience`, `created_at`)
SELECT 'Nida Raza', 'nida.raza@example.com', '03009876543', 1, '2 years', NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_candidate` WHERE email = 'nida.raza@example.com' LIMIT 1);

INSERT INTO `hr_recruit_applications` (`candidate_id`, `post_id`, `source`, `stage`, `application_stage`, `status`, `created_at`)
SELECT c.id, p.id, 'portal', 0, 0, 0, NOW()
FROM `hr_candidate` c
CROSS JOIN `hr_recruit_posts` p
WHERE c.email = 'sara.ahmed@example.com' AND p.title = 'Senior Flutter Developer'
  AND NOT EXISTS (
    SELECT 1 FROM `hr_recruit_applications` a WHERE a.candidate_id = c.id AND a.post_id = p.id
  )
LIMIT 1;

INSERT INTO `hr_recruit_applications` (`candidate_id`, `post_id`, `source`, `stage`, `application_stage`, `status`, `created_at`)
SELECT c.id, p.id, 'manual', 2, 3, 0, NOW()
FROM `hr_candidate` c
CROSS JOIN `hr_recruit_posts` p
WHERE c.email = 'bilal.hussain@example.com' AND p.title = 'Senior Flutter Developer'
  AND NOT EXISTS (
    SELECT 1 FROM `hr_recruit_applications` a WHERE a.candidate_id = c.id AND a.post_id = p.id
  )
LIMIT 1;

INSERT INTO `hr_recruit_applications` (`candidate_id`, `post_id`, `source`, `stage`, `application_stage`, `status`, `created_at`)
SELECT c.id, p.id, 'referral', 1, 2, 0, NOW()
FROM `hr_candidate` c
CROSS JOIN `hr_recruit_posts` p
WHERE c.email = 'nida.raza@example.com' AND p.title = 'HR Business Partner'
  AND NOT EXISTS (
    SELECT 1 FROM `hr_recruit_applications` a WHERE a.candidate_id = c.id AND a.post_id = p.id
  )
LIMIT 1;

INSERT INTO `hr_recruit_interviews` (`application_id`, `title`, `scheduled_at`, `duration_min`, `mode`, `status`, `created_at`)
SELECT a.id, 'Technical Round', DATE_ADD(NOW(), INTERVAL 2 DAY), 60, 'online', 0, NOW()
FROM `hr_recruit_applications` a
JOIN `hr_candidate` c ON c.id = a.candidate_id
WHERE c.email = 'bilal.hussain@example.com'
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_interviews` i WHERE i.application_id = a.id LIMIT 1)
LIMIT 1;

INSERT INTO `hr_recruit_tasks` (`application_id`, `post_id`, `title`, `due_date`, `status`, `created_at`)
SELECT a.id, a.post_id, 'Collect references', DATE_ADD(CURDATE(), INTERVAL 5 DAY), 0, NOW()
FROM `hr_recruit_applications` a
JOIN `hr_candidate` c ON c.id = a.candidate_id
WHERE c.email = 'sara.ahmed@example.com'
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_tasks` t WHERE t.application_id = a.id AND t.title = 'Collect references')
LIMIT 1;

INSERT INTO `hr_recruit_referrals` (`employee_id`, `candidate_name`, `candidate_email`, `post_id`, `status`, `created_at`)
SELECT e.employee_id, 'Nida Raza', 'nida.raza@example.com', p.id, 0, NOW()
FROM `employee` e
CROSS JOIN `hr_recruit_posts` p
WHERE p.title = 'HR Business Partner'
  AND e.user_name = 'admin'
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_referrals` r WHERE r.candidate_email = 'nida.raza@example.com' LIMIT 1)
LIMIT 1;

INSERT INTO `hr_calendar_meetings` (`title`, `agenda`, `meeting_date`, `meeting_time`, `duration_min`, `location`, `created_at`)
SELECT 'Hiring Sync', 'Weekly recruitment standup', CURDATE(), '10:00:00', 45, 'Conference Room A', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_meetings` WHERE title = 'Hiring Sync' LIMIT 1);

INSERT INTO `hr_calendar_events` (`title`, `start_at`, `end_at`, `all_day`, `location`, `description`, `status`, `event_type_id`, `created_at`)
SELECT 'New Hire Orientation', CONCAT(DATE_ADD(CURDATE(), INTERVAL 7 DAY), ' 09:00:00'),
       CONCAT(DATE_ADD(CURDATE(), INTERVAL 7 DAY), ' 12:00:00'), 0, 'Training Hall', 'Onboarding cohort', 1,
       (SELECT id FROM hr_calendar_event_types ORDER BY id LIMIT 1), NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_events` WHERE title = 'New Hire Orientation' LIMIT 1);
