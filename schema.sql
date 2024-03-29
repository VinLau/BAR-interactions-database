-- MySQL Script generated by MySQL Workbench
-- Mon Oct 21 10:52:01 2019
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema interactions_vincent
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `interactions_vincent` ;

-- -----------------------------------------------------
-- Schema interactions_vincent
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `interactions_vincent` ;
USE `interactions_vincent` ;

-- -----------------------------------------------------
-- Table `interactions_vincent`.`interaction_lookup_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`interaction_lookup_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`interaction_lookup_table` (
  `interaction_type_id` INT(2) NOT NULL AUTO_INCREMENT COMMENT 'Surrogate key',
  `description` VARCHAR(100) NOT NULL COMMENT 'Describe the binary interaction of the entities. For example ‘ppi - protein interaction where entity_1_alias and entity_2_alias represent proteins’',
  `entity_1_alias` VARCHAR(50) NOT NULL COMMENT 'Can be a protein, miRNA, etc.',
  `entity_2_alias` VARCHAR(50) NOT NULL COMMENT 'Can be a protein, miRNA, etc.',
  PRIMARY KEY (`interaction_type_id`),
  UNIQUE INDEX `description_UNIQUE` (`description` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`interactions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`interactions` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`interactions` (
  `interaction_id` INT(15) NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
  `pearson_correlation_coeff` DECIMAL(6,5) NULL COMMENT 'PCC score imported from interactions table',
  `entity_1` VARCHAR(50) NOT NULL COMMENT 'Following the interaction_type_id (referencing the lookup table), define the first entity. For example if it is a PPI relationship than the entity 1 shall be a protein with an AGI (ex AT5G01010).',
  `entity_2` VARCHAR(50) NOT NULL COMMENT 'Following the interaction_type_id (referencing the lookup table), define the first entity. For example if it is a PPI relationship than the entity 2 shall be a protein with an AGI (ex AT5G01010).',
  `interaction_type_id` INT(2) NOT NULL COMMENT 'Reference to the lookup of a interactions_lookup_table. Define what type of interaction these two genes are. For example if the value were ‘3’ and it looksup to a PPI, then both members are proteins.',
  PRIMARY KEY (`interaction_id`),
  INDEX `interaction_type_id_idx` (`interaction_type_id` ASC),
  UNIQUE INDEX `unique_interaction_index` (`entity_1` ASC, `entity_2` ASC, `interaction_type_id` ASC),
  CONSTRAINT `interaction_type_id`
    FOREIGN KEY (`interaction_type_id`)
    REFERENCES `interactions_vincent`.`interaction_lookup_table` (`interaction_type_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`interolog_confidence_subset_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`interolog_confidence_subset_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`interolog_confidence_subset_table` (
  `interaction_id` INT(15) NOT NULL COMMENT 'surrogate key',
  `s_cerevisiae` TINYINT(4) NOT NULL COMMENT 'species score… repeat for all other species',
  `s_pombe` TINYINT(4) NOT NULL,
  `worm` TINYINT(4) NOT NULL,
  `fly` TINYINT(4) NOT NULL,
  `human` TINYINT(4) NOT NULL,
  `mouse` TINYINT(4) NOT NULL,
  `e_coli` TINYINT(4) NOT NULL,
  `total_hits` SMALLINT(6) NOT NULL,
  `num_species` TINYINT(4) NOT NULL,
  INDEX `pdi_interaction_id_idx` (`interaction_id` ASC),
  PRIMARY KEY (`interaction_id`),
  CONSTRAINT `interolog_int_id_FK`
    FOREIGN KEY (`interaction_id`)
    REFERENCES `interactions_vincent`.`interactions` (`interaction_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`external_source`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`external_source` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`external_source` (
  `source_id` INT(12) NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
  `source_name` VARCHAR(500) NOT NULL COMMENT 'name of the source, can be a pubmed identifier like “PMIDXXXXXXX” or “Asher’s sql dump”',
  `comments` TEXT NOT NULL COMMENT 'Comments regarding the source',
  `date_uploaded` DATE NOT NULL COMMENT 'When it was uploaded to database',
  `url` VARCHAR(350) NULL COMMENT 'URL if available to paper/source (does not have to be a DOI, can be a link to a databases’ source)',
  `image_url` VARCHAR(300) NULL,
  `grn_title` VARCHAR(200) NULL,
  PRIMARY KEY (`source_id`),
  UNIQUE INDEX `source_name_UNIQUE` (`source_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`modes_of_action_lookup_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`modes_of_action_lookup_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`modes_of_action_lookup_table` (
  `m_of_a_pk` TINYINT(1) NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
  `description` VARCHAR(20) NOT NULL COMMENT 'Describe the mode of action of the interaction, is it repression or activation for example?',
  PRIMARY KEY (`m_of_a_pk`),
  UNIQUE INDEX `description_UNIQUE` (`description` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`interactions_source_mi_join_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`interactions_source_mi_join_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`interactions_source_mi_join_table` (
  `interaction_id` INT(15) NOT NULL COMMENT 'reference the interaction pair via id',
  `source_id` INT(12) NOT NULL COMMENT 'reference the paper/source where this interaction came from',
  `external_db_id` VARCHAR(30) NOT NULL COMMENT 'For the given external_database, like BIOGRID; what is it’s ID?',
  `mode_of_action` TINYINT(1) NOT NULL COMMENT 'Repression or activation? Reference it here to the lookup.',
  `mi_detection_method` VARCHAR(10) NOT NULL,
  `mi_detection_type` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`mi_detection_method`, `mi_detection_type`, `external_db_id`, `interaction_id`, `source_id`),
  INDEX `source_id_idx` (`source_id` ASC),
  INDEX `m_o_a_db_FK_idx` (`mode_of_action` ASC),
  CONSTRAINT `int_id_FK_on_mi_int_src`
    FOREIGN KEY (`interaction_id`)
    REFERENCES `interactions_vincent`.`interactions` (`interaction_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `source_id_FK`
    FOREIGN KEY (`source_id`)
    REFERENCES `interactions_vincent`.`external_source` (`source_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `m_o_a_db_FK`
    FOREIGN KEY (`mode_of_action`)
    REFERENCES `interactions_vincent`.`modes_of_action_lookup_table` (`m_of_a_pk`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`algorithms_lookup_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`algorithms_lookup_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`algorithms_lookup_table` (
  `algo_name` VARCHAR(100) NOT NULL COMMENT 'Algorithm name to be used in place of a surrogate key, assume they’re going to be unique. Like “FIMO”.',
  `algo_desc` VARCHAR(500) NOT NULL COMMENT 'Describe the named algorithm in algo_name.',
  `algo_ranges` VARCHAR(200) NOT NULL COMMENT 'Briefly describe the range of values',
  PRIMARY KEY (`algo_name`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`interactions_algo_score_join_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`interactions_algo_score_join_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`interactions_algo_score_join_table` (
  `algo_score` VARCHAR(30) NOT NULL COMMENT 'Score for that specific algorithm referenced in ‘algo_name’ for a particular binary interaction',
  `interaction_id` INT(15) NOT NULL COMMENT 'The interaction we are looking at when we are referring to an algorithm score',
  `algo_name` VARCHAR(100) NOT NULL COMMENT 'algo_name which will reference the lookup table',
  INDEX `interaction_id_idx` (`interaction_id` ASC),
  PRIMARY KEY (`algo_name`, `interaction_id`, `algo_score`),
  CONSTRAINT `interaction_id`
    FOREIGN KEY (`interaction_id`)
    REFERENCES `interactions_vincent`.`interactions` (`interaction_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `algo_name`
    FOREIGN KEY (`algo_name`)
    REFERENCES `interactions_vincent`.`algorithms_lookup_table` (`algo_name`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`tag_lookup_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`tag_lookup_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`tag_lookup_table` (
  `tag_name` VARCHAR(20) NOT NULL,
  `tag_group` ENUM("Gene", "Experiment", "Condition", "Misc") NOT NULL,
  PRIMARY KEY (`tag_name`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `interactions_vincent`.`source_tag_join_table`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `interactions_vincent`.`source_tag_join_table` ;

CREATE TABLE IF NOT EXISTS `interactions_vincent`.`source_tag_join_table` (
  `source_id` INT(12) NOT NULL,
  `tag_name` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`source_id`, `tag_name`),
  INDEX `tag_join_tag_names_FK_idx` (`tag_name` ASC),
  CONSTRAINT `tag_join_source_id_FK`
    FOREIGN KEY (`source_id`)
    REFERENCES `interactions_vincent`.`external_source` (`source_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `tag_join_tag_names_FK`
    FOREIGN KEY (`tag_name`)
    REFERENCES `interactions_vincent`.`tag_lookup_table` (`tag_name`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
