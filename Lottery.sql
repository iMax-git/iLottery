CREATE TABLE `Lottery` (
  `id` int(255) NOT NULL,
  `license` varchar(255) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `enchere` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `Lottery`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `Lottery`
  MODIFY `id` int(255) NOT NULL AUTO_INCREMENT;

CREATE TABLE `LotteryWinner` (
  `id` int(255) NOT NULL,
  `license` varchar(255) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `WinSum` int(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `LotteryWinner`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `LotteryWinner`
  MODIFY `id` int(255) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;