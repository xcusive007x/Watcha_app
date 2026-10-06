-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 06, 2026 at 05:34 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `watcha_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `knex_migrations`
--

CREATE TABLE `knex_migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `batch` int(11) DEFAULT NULL,
  `migration_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `knex_migrations`
--

INSERT INTO `knex_migrations` (`id`, `name`, `batch`, `migration_time`) VALUES
(1, '20230717184448_create_users_table.ts', 1, '2026-10-02 07:46:29'),
(2, '20230718160813_create_watchlist_table.ts', 1, '2026-10-02 07:46:29'),
(3, '20260924230000_add_watch_url_to_watchlist.ts', 1, '2026-10-02 07:46:29');

-- --------------------------------------------------------

--
-- Table structure for table `knex_migrations_lock`
--

CREATE TABLE `knex_migrations_lock` (
  `index` int(10) UNSIGNED NOT NULL,
  `is_locked` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `knex_migrations_lock`
--

INSERT INTO `knex_migrations_lock` (`index`, `is_locked`) VALUES
(1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `created_at`, `updated_at`) VALUES
(2, 'zxc666', 'test0@gmail.com', '$2b$12$6emuhwwo9l0VR73S2wxgdeaFCIxsuZEIqQT5US7rsMEdjk.we9IMO', '2026-10-02 07:52:33', '2026-10-02 07:52:33'),
(5, 'xyz', 'test01@gmail.com', '$2b$12$a2NKfADEJYTuUgXv/8eeVuA7AVPz3t4D3i3swOfFPblozsjQITJ4C', '2026-10-06 14:08:47', '2026-10-06 14:08:47'),
(6, 'test000', 'test000@gmail.com', '$2b$12$99cfZFFmtJM0kr7FA96Q/OS8knWVSAUi9Vjatumt9P45Cipo8zvWe', '2026-10-06 15:19:42', '2026-10-06 15:19:42');

-- --------------------------------------------------------

--
-- Table structure for table `watchlist`
--

CREATE TABLE `watchlist` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `type` enum('movie','series') NOT NULL,
  `year` int(10) UNSIGNED DEFAULT NULL,
  `status` enum('wishlist','watching','completed') NOT NULL DEFAULT 'wishlist',
  `rating` tinyint(3) UNSIGNED DEFAULT NULL,
  `note` text DEFAULT NULL,
  `poster_url` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `watch_url` varchar(500) DEFAULT NULL
) ;

--
-- Dumping data for table `watchlist`
--

INSERT INTO `watchlist` (`id`, `user_id`, `title`, `type`, `year`, `status`, `rating`, `note`, `poster_url`, `created_at`, `updated_at`, `watch_url`) VALUES
(2, 2, 'Darling in the franxx', 'movie', 2018, 'completed', 5, 'เป็นอนิเมะแนวไซไฟ-เมชา (Sci-fi/Mecha) ที่ร่วมมือกันสร้างโดยสตูดิโอ [A-1 Pictures] และ [Trigger] ออกอากาศครั้งแรกในเดือนมกราคม 2018 มีทั้งหมด 24 ตอน', 'https://www.metalbridges.com/wp-content/uploads/2017/12/DARLING_in_the_FRANKXX_01-e1513926892692.jpg', '2026-10-02 07:55:20', '2026-10-02 07:55:20', 'https://www.crunchyroll.com/th/series/GY8VEQ95Y/darling-in-the-franxx'),
(4, 2, 'Darling in the franxx', 'series', 2018, 'completed', 5, 'เป็นอนิเมะแนวไซไฟ-เมชา (Sci-fi/Mecha) ที่ร่วมมือกันสร้างโดยสตูดิโอ [A-1 Pictures] และ [Trigger] ออกอากาศครั้งแรกในเดือนมกราคม 2018 มีทั้งหมด 24 ตอน', 'https://www.metalbridges.com/wp-content/uploads/2017/12/DARLING_in_the_FRANKXX_01-e1513926892692.jpg', '2026-10-02 07:55:20', '2026-10-02 07:55:20', 'https://www.youtube.com/watch?v=KD97F12ysD4'),
(5, 2, 'test', 'series', 2020, 'wishlist', NULL, '', 'https://m.media-amazon.com/images/M/MV5BZjliODY5MzQtMmViZC00MTZmLWFhMWMtMjMwM2I3OGY1MTRiXkEyXkFqcGc@._V1_QL75_UY281_CR5,0,190,281_.jpg', '2026-10-06 09:20:42', '2026-10-06 09:20:42', NULL),
(9, 2, 'Zonic', 'movie', 2000, 'wishlist', NULL, 'testttt', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZ-JNNOjf7Kb_w2918P6qFH_A8_WRgNjkDdkP_0ExW_M2CY241k3HmJf4&s=10', '2026-10-06 15:10:32', '2026-10-06 15:10:32', 'https://www.roblox.com/users/598262558/profile'),
(11, 6, 'Black Clover', 'series', 2014, 'wishlist', NULL, 'อัสตาและยูโนเด็กกำพร้าที่เติบโตมาด้วยกัน แข่งขันกันเพื่อก้าว เป็น \"จักรพรรดิเวทมนตร์\" อัสตาผู้ไร้พลังเวท แต่ฝึกฝนร่างกายอย่างหนัก ได้รับคัมภีร์ใบโคลเวอร์ 5 แฉก', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZ-JNNOjf7Kb_w2918P6qFH_A8_WRgNjkDdkP_0ExW_M2CY241k3HmJf4&s=10', '2026-10-06 15:20:36', '2026-10-06 15:20:36', 'https://www.trueid.net/watch/th-th/series/mgpbqRvN7bR5/VYmV5PjlLN1z/5by3o8Q0r6dX/mw7jMo7VyPoJ');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `knex_migrations`
--
ALTER TABLE `knex_migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `knex_migrations_lock`
--
ALTER TABLE `knex_migrations_lock`
  ADD PRIMARY KEY (`index`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indexes for table `watchlist`
--
ALTER TABLE `watchlist`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_watchlist_user_status` (`user_id`,`status`),
  ADD KEY `idx_watchlist_user_title` (`user_id`,`title`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `knex_migrations`
--
ALTER TABLE `knex_migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `knex_migrations_lock`
--
ALTER TABLE `knex_migrations_lock`
  MODIFY `index` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `watchlist`
--
ALTER TABLE `watchlist`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `watchlist`
--
ALTER TABLE `watchlist`
  ADD CONSTRAINT `watchlist_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
