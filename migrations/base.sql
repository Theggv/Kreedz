-- VERSION 1.0.1
ALTER TABLE `kz_savedruns` ADD `lastvel_x` int(11) NOT NULL DEFAULT 0;
ALTER TABLE `kz_savedruns` ADD `lastvel_y` int(11) NOT NULL DEFAULT 0;
ALTER TABLE `kz_savedruns` ADD `lastvel_z` int(11) NOT NULL DEFAULT 0;

-- VERSION 1.1.2
-- Pro records
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`) 
    (SELECT `uid`, `mapid`, `time`, `date` FROM `kz_protop` WHERE 1); 

-- Nub records
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`, `cp`, `tp`) 
   (SELECT `uid`, `mapid`, `time`, `date`, `cp`, `tp` FROM `kz_nubtop` WHERE 1);

-- Weapon records
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`, `cp`, `tp`, `weapon`) 
    (SELECT `uid`, `mapid`, `time`, `date`, `cp`, `tp`, `weapon` FROM `kz_weapontop` WHERE 1); 