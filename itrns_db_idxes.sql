/* e_1_idx and e_2_idx for fast querying of finding AGIs in either direction/pair */
CREATE INDEX e_1_idx ON interactions (entity_1);
CREATE INDEX e_2_idx ON interactions (entity_2);