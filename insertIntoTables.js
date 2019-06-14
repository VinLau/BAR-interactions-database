const knex = require('./dbConfig.js');

const fs = require('fs');

/**
 * Interaction lookup table initial definitions
 */
knex('interaction_lookup_table').insert([
  {
    description: 'protein-protein interaction (ppi)',
    entity_1_alias : 'protein',
    entity_2_alias : 'protein'
  },
  {
    description: 'protein-dna interaction (pdi)',
    entity_1_alias : 'protein',
    entity_2_alias : 'dna'
  },
  {
    description: 'mirna-mrna interaction (mimi)',
    entity_1_alias : 'mirna',
    entity_2_alias : 'mrna'
  }
])
.then((rows)=>{console.log('int lookup table success!', rows)});

/**
 * Mode of action lookup table initial definitions
 */
knex('modes_of_action_lookup_table').insert([
  {
    description : "unknown"
  },
  {
    description : "activation"
  },
  {
    description : "repression"
  }
])
.then((rows)=>{ console.log('MoA db ids lookup table success!', rows)});

/**
 * Algorithm score lookup table initial definitions
 */

knex('algorithms_lookup_table').insert([
  {
    algo_name : "FIMO-Yu",
    algo_desc : "Yu et al (PMID: 27117388) used the FIMO tool to predict TFBSs (multiple source, see paper) at a promoter.",
    algo_ranges : "Values represent p-values, the lower the better should be all smaller than < 10^-4 and non-negative"
  },
  {
    algo_name : "S-PPI-Dong",
    algo_desc : "Dong et al (PMID: 30679268) used the HEX tool to predict protein-pairs",
    algo_ranges : "9065 PPI pairs were predicted, 1 is the best ranked protein pair and 9065 is the worst"
  },
  {
    algo_name : "Interolog-Geiser-Lee",
    algo_desc : "Geiser-Lee et al (PMID: 17675552) used a pipeline (including tools such as INPARANOID) to predict PPIs via interologs",
    algo_ranges : "Number represents confidence value where the greater the number, the greater the confidence"
  }
])
.then((rows)=>{ console.log('Algo lookup db ids lookup table success!', rows)})

inserts()

// end connection
.finally(() => {knex.destroy();});

/**
 Eddi's TSV file
 1st col - aiv_index
 2 PMID2
 3 Protein1
 4 Protein2
 5 MI_interaction_detection_method
 6 MI_interaction_type
 7 alt_ids2
 8 Quality
 9 Pcc
 10 S_cerevisiae
 11 S_pombe
 12 Worm
 13 Fly
 14 Human
 15 Mouse
 16 E_coli
 17 Total_hits
 18 Num_species

 * General outline:
 * (Check and) add Interaction - store int_id
 *  -> Store interologs if exists
 *  -> Store algo scores if exists
 * (Check and) add source - store source_id
 * INSERT Join table
 */

async function inserts() {
  const tsv = fs.readFileSync('finalDump_2019-05-14.tsv', 'utf8');
  const lines = tsv.split('\n');
  let count = 0;
  for (let [idx, line] of lines.entries()){
    const tabVals = line.split('\t');

    if (idx === 0 || idx === lines.length - 1) continue; // skip header and end line
    if (tabVals[0] === "1.0") continue; // skip repeated-PPIs

    await knex('interactions').select('*').where({
      entity_1 : tabVals[2],
      entity_2 : tabVals[3],
      interaction_type_id : getItrnIdx(Number(tabVals[0]))
    })
      .then(  (rows)=>{
        console.log('INSERT initialization', rows);
        if (rows.length === 0 ){
          count++;
          console.log(`Interaction NOT FOUND ${tabVals[2]}-${tabVals[3]} of AIV-index ${tabVals[0]} with pcc ${tabVals[8]}, INSERTing - line ${idx}`);
          return knex('interactions').insert({
            entity_1 : tabVals[2],
            entity_2 : tabVals[3],
            interaction_type_id : getItrnIdx(Number(tabVals[0])),
            pearson_correlation_coeff : tabVals[8] || null
          })
        }
        else {
          console.log(`Interaction Found: ${tabVals[2]}-${tabVals[3]} of AIV-index ${tabVals[0]} - line ${idx}`);
          return rows;
        }
      })
      .then(async (rows)=>{
        let interactionId = typeof rows[0] === "number" ? rows[0] : rows[0].interaction_id; // if row freshly inserted (will return [1001]) or not (will return [ RowDataPacket {interaction_id : 1001}]
        console.log('Interaction ID:', interactionId);
        console.log(tabVals[17], tabVals[16]);
        if (tabVals[17] === "0.0" && tabVals[16] === "0.0") { console.log('lol'); return interactionId } // don't enter zero-values
        const interologSubsetSelect = await knex('interolog_confidence_subset_table').select('*').where('interaction_id', interactionId);
        if (interologSubsetSelect.length === 0){
          return knex('interolog_confidence_subset_table').insert({
            interaction_id : interactionId,
            s_cerevisiae   : tabVals[9],
            s_pombe        : tabVals[10],
            worm           : tabVals[11],
            fly            : tabVals[12],
            human          : tabVals[13],
            mouse          : tabVals[14],
            e_coli         : tabVals[15],
            total_hits     : tabVals[16],
            num_species    : tabVals[17],
          }).return(interactionId)
        }
        else {
          return interactionId;
        }
      })
      .then( async (itrnId)=>{
        console.log('3rd cb', itrnId);
        if (tabVals[7] === "0.0") return itrnId;
        const algoName = determineAlgo(tabVals[7]);
        const algoScorePerItrnSubset = await knex('interactions_algo_score_join_table').select('*').where({
          algo_name : algoName[0],
          interaction_id : itrnId,
          algo_score : algoName[1]
        });
        if (algoScorePerItrnSubset.length === 0){
          return knex('interactions_algo_score_join_table').insert({
            algo_name : algoName[0],
            interaction_id : itrnId,
            algo_score : algoName[1]
          }).return(itrnId)
        }
        else {
          return itrnId
        }
      })
      .then(async(itrnId)=>{
        console.log('4th cb', itrnId);
        const pmid = tabVals[1].replace('-', '#'); // note replace 29320478-2 for 29320478#2 as it will be work better for linking
        const sourcePreSelect = await knex('external_source').select('*').where({
          source_name : pmid
        });
        console.log(pmid, 'pmid');
        if (sourcePreSelect.length === 0){
          return knex('external_source').insert({
            source_name : pmid,
            comments : initCmtsForRefs(pmid),
            date_uploaded : new Date(),
          })
            .then((instdRow) => {return {source : instdRow[0], itrnId}})
        }
        else {
          return {source : sourcePreSelect[0].source_id, itrnId};
        }
      })
      .then(async(sourceAndItrnIds)=>{
        console.log('source and itrn Ids\n', sourceAndItrnIds);
        const miMethod = tabVals[4] || "";
        const miType = tabVals[5] || "";
        const bindId = tabVals[6] || "";
        const joinTablePreSelect = await knex('interactions_source_mi_join_table').where({
          interaction_id : sourceAndItrnIds.itrnId,
          source_id : sourceAndItrnIds.source,
          external_db_id : bindId,
          mi_detection_method : miMethod,
          mi_detection_type : miType
        });
        if (joinTablePreSelect.length === 0 ) {
          return knex('interactions_source_mi_join_table').insert({
            interaction_id : sourceAndItrnIds.itrnId,
            source_id : sourceAndItrnIds.source,
            external_db_id : bindId,
            mi_detection_method : miMethod,
            mi_detection_type : miType,
            mode_of_action : 1
          });
        }
      })
      .catch((err)=>{
        console.error('Error:', err);
        throw new Error('STOP!');
      })

  }

  console.log(count);
};

function getItrnIdx (AIVIndex) {
  return {
    0.0 : 1,
    2.0 : 2
  }[AIVIndex]
}

function determineAlgo (algoScore) {
  if (algoScore <= -1){
    return ["S-PPI-Dong", Math.abs(parseInt(algoScore))] // i.e. turn our negative ranking into a positive one (i.e. -32 to 32)
  }
  else if (algoScore >= 1) {
    return ["Interolog-Geiser-Lee", algoScore]
  }
  else if (algoScore > 0){ // FIMO scores between 1 and 0 but 1 already considered above
    return ["FIMO-Yu", algoScore]
  }
  else {
    return false
  }
}

function initCmtsForRefs (pmid) {
  if (pmid === "21798944-1"){
    return "Initial Arabidopsis Interactome interactions";
  }
  else if (pmid === "21798944-2"){
    return "Authors re-tested subset of Arabidopsis Interactome-MAIN subset (-1)";
  }
  else if (pmid === "29320478-1"){
    return 'From paper: "[H]ig h-confidence interactions (HCi)) passed our extremely stringent statistical cut-offs for network construction"';
  }
  else if (pmid === "29320478-2"){
    return "Low confidence interaction set sent to Nick, extended data set 3";
  }
  else if (pmid === "Id missing"){
    return "According to Eddi, bind ids were converted to pmids using a lookup provided by the original bind coordinator. That lookup did not have a pmid in some instances, and they make up \"id missing\" cases";
  }
  else if (pmid === "mind_pmid"){
    return "Placeholder pmid for the mind data we got directly via email correspondence from the mind team, which were separate from data in the mind team's original public mind database";
  }
  else {
    return "initial DB migration nodejs script - vincent";
  }
}