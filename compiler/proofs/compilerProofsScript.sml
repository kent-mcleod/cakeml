open HolKernel bossLib boolLib boolSimps listTheory rich_listTheory pred_setTheory relationTheory arithmeticTheory whileTheory pairTheory quantHeuristicsLib lcsymtacs sortingTheory finite_mapTheory alistTheory optionTheory stringTheory
open SatisfySimps miscLib BigStepTheory terminationTheory semanticsExtraTheory miscTheory ToBytecodeTheory CompilerTheory compilerTerminationTheory intLangExtraTheory pmatchTheory toIntLangProofsTheory toBytecodeProofsTheory bytecodeTerminationTheory bytecodeExtraTheory bytecodeEvalTheory bigClockTheory replTheory
val _ = new_theory"compilerProofs"

val FOLDL_cce_aux_thm = store_thm("FOLDL_cce_aux_thm",
  ``∀menv c s. let s' = FOLDL (cce_aux menv) s c in
     ALL_DISTINCT (MAP (FST o FST) c) ∧
     EVERY (combin$C $< s.next_label) (MAP (FST o FST) c)
      ⇒
     ∃code.
     (s'.out = REVERSE code ++ s.out) ∧
     (s.next_label ≤ s'.next_label) ∧
     ALL_DISTINCT (FILTER is_Label code) ∧
     EVERY (λn. MEM n (MAP (FST o FST) c) ∨ between s.next_label s'.next_label n)
       (MAP dest_Label (FILTER is_Label code)) ∧
     ∃cs.
     ∀i. i < LENGTH c ⇒ let ((l,ccenv,ce),(az,body)) = EL i c in
         s.next_label ≤ (cs i).next_label ∧
         (∀j. j < i ⇒ (cs j).next_label ≤ (cs i).next_label) ∧
         ∃cc. ((compile menv (MAP CTEnv ccenv) (TCTail az 0) 0 (cs i) body).out = cc ++ (cs i).out) ∧
              l < (cs i).next_label ∧
              ∃bc0 bc1. (code = bc0 ++ Label l::REVERSE cc ++ bc1) ∧
                        EVERY (combin$C $< (cs i).next_label o dest_Label)
                          (FILTER is_Label bc0)``,
   gen_tac >> Induct >- ( simp[Once SWAP_REVERSE] ) >>
   simp[] >>
   qx_gen_tac`p`>> PairCases_on`p` >>
   rpt gen_tac >>
   simp[cce_aux_def] >>
   strip_tac >>
   Q.PAT_ABBREV_TAC`s0 = s with out := X::y` >>
   qspecl_then[`menv`,`MAP CTEnv p1`,`TCTail p3 0`,`0`,`s0`,`p4`]
     strip_assume_tac(CONJUNCT1 compile_append_out) >>
   Q.PAT_ABBREV_TAC`s1 = compile menv X Y Z A B` >>
   first_x_assum(qspecl_then[`s1`]mp_tac) >>
   simp[] >>
   discharge_hyps >- (
     fsrw_tac[ARITH_ss][EVERY_MEM,Abbr`s0`] >>
     rw[] >> res_tac >> DECIDE_TAC ) >>
   disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
   simp[Abbr`s0`] >>
   simp[Once SWAP_REVERSE] >>
   fs[] >> simp[] >>
   simp[FILTER_APPEND,FILTER_REVERSE,MEM_FILTER,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND] >>
   conj_tac >- (
     rfs[FILTER_APPEND] >>
     fs[EVERY_MAP,EVERY_FILTER,EVERY_REVERSE,between_def] >>
     fsrw_tac[DNF_ss,ARITH_ss][EVERY_MEM,MEM_MAP] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][]
       >- metis_tac[] >>
     res_tac >> fsrw_tac[ARITH_ss][] ) >>
   conj_tac >- (
     fs[EVERY_MAP,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
     fsrw_tac[DNF_ss][EVERY_MEM,between_def] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >>
     fsrw_tac[ARITH_ss][] ) >>
   qexists_tac`λi. if i = 0 then (s with out := Label p0::s.out) else cs (i-1)` >>
   Cases >> simp[] >- (
     map_every qexists_tac[`[]`,`c0`] >> simp[] ) >>
   strip_tac >>
   first_x_assum(qspec_then`n`mp_tac) >>
   simp[UNCURRY] >> strip_tac >>
   simp[] >>
   conj_asm1_tac >- ( Cases >> simp[] ) >>
   qexists_tac`Label p0::(REVERSE bc ++ bc0)` >>
   simp[FILTER_APPEND,FILTER_REVERSE,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
   qpat_assum`EVERY X (FILTER is_Label bc0)`mp_tac >>
   qpat_assum`EVERY X (MAP Y (FILTER is_Label bc))`mp_tac >>
   simp[EVERY_FILTER,EVERY_MAP,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def] >>
   asm_simp_tac(srw_ss()++ARITH_ss++DNF_ss)[EVERY_MEM] >>
   rw[] >> res_tac >> DECIDE_TAC)

val compile_code_env_thm = store_thm("compile_code_env_thm",
  ``∀ez menv s e. let s' = compile_code_env menv s e in
      ALL_DISTINCT (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY (combin$C $< s.next_label) (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY good_cd (free_labs ez e)
      ⇒
      ∃code.
      (s'.out = REVERSE code ++ s.out) ∧
      (s.next_label < s'.next_label) ∧
      ALL_DISTINCT (FILTER is_Label code) ∧
      EVERY (λn. MEM n (MAP (FST o FST o SND) (free_labs ez e)) ∨ between s.next_label s'.next_label n)
        (MAP dest_Label (FILTER is_Label code)) ∧
      ∀bs bc0 bc1.
        (bs.code = bc0 ++ code ++ bc1) ∧
        (bs.pc = next_addr bs.inst_length bc0) ∧
        ALL_DISTINCT (FILTER is_Label bc0) ∧
        (∀l1 l2. MEM l1 (MAP dest_Label (FILTER is_Label bc0)) ∧ ((l2 = s.next_label) ∨ MEM l2 (MAP (FST o FST o SND) (free_labs ez e))) ⇒ l1 < l2)
        ⇒
        EVERY (code_env_cd menv (bc0++code)) (free_labs ez e) ∧
        bc_next bs (bs with pc := next_addr bs.inst_length (bc0++code))``,
  rw[compile_code_env_def] >> rw[] >>
  `MAP SND (free_labs 0 e) = MAP SND (free_labs ez e)` by metis_tac[MAP_SND_free_labs_any_ez] >>
  fs[] >>
  Q.ISPECL_THEN[`menv`,`MAP SND (free_labs ez e)`,`s''`]mp_tac FOLDL_cce_aux_thm >>
  simp[Abbr`s''`] >>
  discharge_hyps >- (
    fsrw_tac[ARITH_ss][EVERY_MEM,MAP_MAP_o] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  simp[Once SWAP_REVERSE,Abbr`s''''`] >>
  conj_tac >- (
    simp[ALL_DISTINCT_APPEND,FILTER_APPEND,MEM_FILTER] >>
    fs[EVERY_MAP,EVERY_FILTER] >> fs[EVERY_MEM] >>
    spose_not_then strip_assume_tac >> res_tac >>
    fsrw_tac[ARITH_ss][between_def,MEM_MAP,MAP_MAP_o] >>
    res_tac >> rw[] >> DECIDE_TAC ) >>
  conj_tac >- (
    fs[EVERY_MAP,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def] >>
    reverse conj_tac >- (disj2_tac >> DECIDE_TAC) >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_MAP,FORALL_PROD,EXISTS_PROD] >>
    rw[] >> res_tac >>
    TRY(metis_tac[]) >>
    disj2_tac >> DECIDE_TAC ) >>
  rpt gen_tac >>
  strip_tac >>
  conj_tac >- (
    fs[EVERY_MEM] >>
    qx_gen_tac`z` >>
    PairCases_on`z` >> strip_tac >>
    simp[code_env_cd_def] >>
    qmatch_assum_abbrev_tac`MEM cd (free_labs ez e)` >>
    `∃i. i < LENGTH (free_labs ez e) ∧ (EL i (free_labs ez e) = cd)` by metis_tac[MEM_EL] >>
    qpat_assum`∀i. P ⇒ Q`(qspec_then`i`mp_tac) >>
    simp[EL_MAP] >>
    simp[Abbr`cd`] >> strip_tac >>
    qexists_tac`cs i`>>simp[] >>
    qexists_tac`bc0++Jump (Lab s.next_label)::bc0'` >>
    simp[] >>
    fs[EVERY_MEM,MEM_MAP,FILTER_APPEND] >>
    fsrw_tac[DNF_ss][] >- (
      rpt strip_tac >> res_tac >> DECIDE_TAC) >>
    rpt strip_tac >> res_tac >> DECIDE_TAC) >>
  `bc_fetch bs = SOME (Jump (Lab s.next_label))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0` >> simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def,bc_state_component_equality,bc_find_loc_def] >>
  match_mp_tac bc_find_loc_aux_append_code >>
  match_mp_tac bc_find_loc_aux_ALL_DISTINCT >>
  qexists_tac`LENGTH bc0 + 1 + LENGTH c0` >>
  simp[EL_APPEND2,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER] >>
  fs[EVERY_MAP,EVERY_FILTER,between_def] >>
  fsrw_tac[DNF_ss][EVERY_MEM,is_Label_rwt,MEM_MAP,EXISTS_PROD,FORALL_PROD,MEM_FILTER] >>
  rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] >>
  res_tac >> fsrw_tac[ARITH_ss][])

val code_env_cd_append = store_thm("code_env_cd_append",
  ``∀menv code cd code'. code_env_cd menv code cd ∧ ALL_DISTINCT (FILTER is_Label (code ++ code')) ⇒ code_env_cd menv (code ++ code') cd``,
  rw[] >> PairCases_on`cd` >>
  fs[code_env_cd_def] >>
  HINT_EXISTS_TAC>>simp[]>>
  HINT_EXISTS_TAC>>simp[])

val good_contab_def = Define`
  good_contab ((m,w,n):contab) ⇔
    ALL_DISTINCT (MAP FST w) ∧
    ALL_DISTINCT (MAP SND w) ∧
    EVERY (combin$C $< n) (MAP FST w) ∧
    set (MAP SND w) ⊆ (FDOM m) ∧
    cmap_linv m w`

val env_rs_def = Define`
  env_rs menv cenv env rs rd s bs ⇔
    good_contab rs.contab ∧
    good_cmap cenv (cmap rs.contab) ∧
    (({Short ""} ∪ set (MAP FST cenv)) = FDOM (cmap rs.contab)) ∧
    Short "" ∉ set (MAP FST cenv) ∧
    (∀id. (FLOOKUP (cmap rs.contab) id = SOME ((cmap rs.contab) ' (Short ""))) ⇒ (id = Short "")) ∧
    let fmv = alist_to_fmap menv in
    let mv = MAP FST o_f fmv in
    let Cs0 = MAP (v_to_Cv mv (cmap rs.contab)) (SND s) in
    let Cenv0 = env_to_Cenv mv (cmap rs.contab) env in
    let Cmenv0 = env_to_Cenv mv (cmap rs.contab) o_f fmv in
    let cmnv = MAP SND o_f rs.rmenv in
    ∃Cmenv Cenv Cs.
    LIST_REL syneq Cs0 Cs ∧ LIST_REL syneq Cenv0 Cenv ∧ fmap_rel (LIST_REL syneq) Cmenv0 Cmenv ∧
    (BIGUNION (IMAGE (BIGUNION o IMAGE all_Clocs o set) (FRANGE Cmenv)) ⊆ count (LENGTH Cs)) ∧
    (BIGUNION (IMAGE all_Clocs (set Cs)) ⊆ count (LENGTH Cs)) ∧
    (BIGUNION (IMAGE all_Clocs (set Cenv)) ⊆ count (LENGTH Cs)) ∧
    EVERY all_vlabs Cs ∧ EVERY all_vlabs Cenv ∧ all_vlabs_menv Cmenv ∧
    (∀cd. cd ∈ vlabs_list Cs ⇒ code_env_cd cmnv bs.code cd) ∧
    (∀cd. cd ∈ vlabs_list Cenv ⇒ code_env_cd cmnv bs.code cd) ∧
    (∀cd. cd ∈ vlabs_menv Cmenv ⇒ code_env_cd cmnv bs.code cd) ∧
    (MAP FST rs.renv = MAP FST env) ∧ (mv = MAP FST o_f rs.rmenv) ∧
    rs.rsz = LENGTH rs.renv + SIGMA I (IMAGE LENGTH (FRANGE rs.rmenv)) ∧
    rs.rsz = LENGTH bs.stack ∧
    Cenv_bs rd Cmenv (FST s, Cs) Cenv cmnv (MAP (CTDec o SND) rs.renv) rs.rsz rs.rsz bs`

val _ = Parse.overload_on("print_bv",``λm. ov_to_string o bv_to_ov m``)
val print_bv_str_def = Define`print_bv_str m v w = "val "++v++" = "++(print_bv m w)++"\n"`

val FOLDL_emit_thm = store_thm("FOLDL_emit_thm",
  ``∀ls s. FOLDL (λs i. s with out := i::s.out) s ls = s with out := REVERSE ls ++ s.out``,
  Induct >> simp[compiler_result_component_equality])

val append_cons_lemma = prove(``ls ++ [x] ++ a::b = ls ++ x::a::b``,lrw[])

val MAP_PrintC_thm = store_thm("MAP_PrintC_thm",
  ``∀ls bs bc0 bc1 bs'.
    bs.code = bc0 ++ (MAP PrintC ls) ++ bc1 ∧
    bs.pc = next_addr bs.inst_length bc0 ∧
    bs' = bs with <| output := REVERSE ls ++ bs.output; pc := next_addr bs.inst_length (bc0 ++ (MAP PrintC ls))|>
    ⇒
    bc_next^* bs bs'``,
  Induct >- (
    simp[] >> rw[] >>
    simp[Once RTC_CASES1] >> disj1_tac >>
    simp[bc_state_component_equality] ) >>
  simp[] >> rw[] >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs = SOME (PrintC h)` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0` >>
    simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def,bump_pc_def] >>
  first_x_assum match_mp_tac >>
  simp[bc_state_component_equality] >>
  qexists_tac`bc0 ++ [PrintC h]` >>
  simp[FILTER_APPEND,SUM_APPEND])

val _ = Parse.overload_on("print_bv_list",``λm vs ws. FLAT (REVERSE (MAP (REVERSE o (UNCURRY (print_bv_str m))) (ZIP (vs,ws))))``)

val compile_news_thm = store_thm("compile_news_thm",
  ``∀vs pr cs i. let cs' = compile_news pr cs i vs in
      ∃code.
        (cs'.out = REVERSE code ++ cs.out) ∧
        (cs'.next_label = cs.next_label) ∧
        EVERY ($~ o is_Label) code ∧
        ∀bs bc0 u ws st.
          (bs.code = bc0 ++ code) ∧
          (bs.pc = next_addr bs.inst_length bc0) ∧
          (bs.stack = Block u ws::st) ∧
          (LENGTH ws = LENGTH vs + i)
          ⇒
          let bs' =
          bs with <| pc := next_addr bs.inst_length (bc0 ++ code)
                   ; stack := Block u ws::(REVERSE (DROP i ws))++st
                   ; output := if pr then
                     FLAT (REVERSE (MAP (REVERSE o (UNCURRY (print_bv_str bs.cons_names))) (ZIP (vs, DROP i ws)))) ++ bs.output
                     else bs.output
                   |> in
          bc_next^* bs bs'``,
  Induct >- (
    simp[compile_news_def,Once SWAP_REVERSE] >> rw[] >>
    simp[Once RTC_CASES1] >> disj1_tac >>
    simp[bc_state_component_equality,DROP_LENGTH_NIL]) >>
  qx_gen_tac`v` >>
  simp[compile_news_def,FOLDL_emit_thm] >>
  rpt gen_tac >>
  simp[append_cons_lemma,IMPLODE_EXPLODE_I,REVERSE_APPEND] >>
  REWRITE_TAC[prove(``REVERSE (MAP PrintC v) ++ ls ++ cs.out = REVERSE (MAP PrintC v) ++ (ls ++ cs.out)``,lrw[])] >>
  REWRITE_TAC[prove(``[a;b;c;d;e;f;g]++ls = a::b::c::d::e::f::g::ls``,lrw[])] >>
  Q.PAT_ABBREV_TAC`c1 = Stack (El i)::X` >>
  Q.PAT_ABBREV_TAC`cs0 = if pr then X else Y:compiler_result` >>
  Q.PAT_ABBREV_TAC`cs1 = cs0 with out := X` >>
  first_x_assum(qspecl_then[`pr`,`cs1`,`i+1`]mp_tac) >>
  simp[] >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  `cs1.next_label = cs.next_label ∧ ∃code. cs1.out = code ++ c1 ∧ EVERY ($~ o is_Label) code` by (
    simp[Abbr`cs1`,Abbr`cs0`] >> rw[] >> rw[EVERY_REVERSE,EVERY_MAP] ) >>
  simp[Once SWAP_REVERSE,EVERY_REVERSE,Abbr`c1`] >>
  rpt gen_tac >> strip_tac >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs = SOME (Stack (Load 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0`>>simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (Load 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 1) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (El i))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 2) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  `bc_next^* bs1 (bs1 with <| output := if pr then REVERSE (print_bv_str bs.cons_names v (EL i ws)) ++ bs.output else bs.output
                            ; pc := next_addr bs'.inst_length (BUTLASTN (LENGTH c0 + 1) bs'.code)|>)` by (
    reverse(Cases_on`pr`) >- (
      simp[Once RTC_CASES1] >> disj1_tac >>
      simp[bc_state_component_equality,Abbr`bs1`] >>
      simp[Abbr`bs'`] >> fs[Abbr`cs1`,Abbr`cs0`] >>
      rw[] >>
      simp[BUTLASTN_APPEND1,BUTLASTN_APPEND2,BUTLASTN] >>
      simp[FILTER_APPEND,SUM_APPEND] ) >>
    fs[Abbr`cs0`,Abbr`cs1`] >> rw[] >> fs[EVERY_REVERSE,EVERY_MAP] >> rw[] >>
    fs[REVERSE_APPEND] >>
    first_x_assum(qspec_then`bs`kall_tac) >>
    qpat_assum`X = Y.next_label`kall_tac >>
    qpat_assum`X.out = Y`kall_tac >>
    simp[print_bv_str_def,REVERSE_APPEND] >>
    qmatch_assum_abbrev_tac `bs.code = bc0 ++ c3 ++ c2 ++ c1 ++ c0` >>
    `bc_next^* bs1 (bs1 with <| output := REVERSE ("val "++v++" = ") ++ bs1.output
                              ; pc := next_addr bs1.inst_length (bc0 ++ c3 ++ c2 ++ (TAKE 3 c1)) |>)` by (
      match_mp_tac MAP_PrintC_thm >>
      qexists_tac`"val "++v++" = "` >>
      simp[bc_state_component_equality] >>
      qexists_tac`bc0 ++ TAKE 3 c3` >>
      simp[Abbr`bs1`,Abbr`c3`,Abbr`c1`] >>
      simp[SUM_APPEND,FILTER_APPEND] ) >>
    qmatch_assum_abbrev_tac`bc_next^* bs1 bs2` >>
    qmatch_abbrev_tac`bc_next^* bs1 bs3` >>
    qsuff_tac`bc_next^* bs2 bs3` >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
    qpat_assum`bc_next^* bs1 bs2`kall_tac >> qunabbrev_tac`bs1` >> fs[] >>
    `bc_fetch bs2 = SOME (Stack (Load 0))` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs2`] >>
      qexists_tac`bc0 ++ c3 ++ c2 ++ TAKE 3 c1` >>
      simp[Abbr`c1`] ) >>
    simp[Once RTC_CASES1] >> disj2_tac >>
    simp[bc_eval1_thm,bc_eval1_def,bump_pc_def] >>
    pop_assum kall_tac >>
    simp[Abbr`bs2`,bc_eval_stack_def] >>
    qmatch_abbrev_tac`bc_next^* bs1 bs3` >>
    `bc_fetch bs1 = SOME Print` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs1`] >>
      qexists_tac`bc0 ++ c3 ++ c2 ++ TAKE 4 c1` >>
      simp[Abbr`c1`] >>
      simp[SUM_APPEND,FILTER_APPEND]) >>
    simp[Once RTC_CASES1] >> disj2_tac >>
    simp[bc_eval1_thm,bc_eval1_def,bump_pc_def] >>
    pop_assum kall_tac >>
    simp[Abbr`bs1`] >>
    qmatch_abbrev_tac`bc_next^* bs1 bs3` >>
    match_mp_tac MAP_PrintC_thm >>
    qexists_tac`"\n"` >>
    simp[bc_state_component_equality,Abbr`bs1`,Abbr`bs3`,IMPLODE_EXPLODE_I] >>
    CONV_TAC SWAP_EXISTS_CONV >>
    qexists_tac`LAST c1::c0` >>
    simp[Abbr`c1`] >>
    simp[SUM_APPEND,FILTER_APPEND,Abbr`bs'`] >>
    simp[BUTLASTN_APPEND1,BUTLASTN_APPEND2] >>
    REWRITE_TAC[BUTLASTN_compute] >>
    simp[SUM_APPEND,FILTER_APPEND] ) >>
  qmatch_assum_abbrev_tac`bc_next^* bs1 bs2` >>
  qsuff_tac`bc_next^* bs2 bs'` >- metis_tac[RTC_TRANSITIVE,transitive_def] >>
  qpat_assum`bc_next^* bs1 X`kall_tac >> qunabbrev_tac`bs1` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs2 = SOME (Stack (Store 1))` by (
    match_mp_tac bc_fetch_next_addr >>
    simp[Abbr`bs2`] >>
    qexists_tac`BUTLASTN (LENGTH c0 + 1) bs'.code` >>
    simp[Abbr`bs'`,BUTLASTN_APPEND1] >>
    REWRITE_TAC[BUTLASTN_compute] >>
    simp[TAKE_APPEND1,TAKE_APPEND2] >>
    fs[Abbr`cs1`,Abbr`cs0`] >>
    Cases_on`pr`>>fs[]>>rw[]>>simp[TAKE_APPEND1,TAKE_APPEND2] ) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs2`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  first_x_assum(qspecl_then[`bs1`,`BUTLASTN (LENGTH c0) bs.code`]mp_tac) >>
  simp[Abbr`bs1`] >>
  qmatch_abbrev_tac`(P ⇒ Q) ⇒ R` >>
  `P` by (
    simp[Abbr`P`,BUTLASTN_APPEND1,BUTLASTN] >>
    REWRITE_TAC[BUTLASTN_compute] >>
    simp[Abbr`bs'`] >>
    Cases_on`pr`>>fs[Abbr`cs0`,Abbr`cs1`]>>rw[]>>
    simp[SUM_APPEND,FILTER_APPEND,TAKE_APPEND1,TAKE_APPEND2] ) >>
  simp[Abbr`P`,Abbr`Q`,Abbr`R`] >>
  qmatch_abbrev_tac`bc_next^* bs1' bs2 ⇒ bc_next^* bs1 bs'` >>
  `bs1' = bs1` by (
    simp[Abbr`bs1`,Abbr`bs1'`,bc_state_component_equality] ) >>
  `bs2 = bs'` by (
    simp[Abbr`bs2`,Abbr`bs'`,bc_state_component_equality] >>
    conj_asm1_tac >- (
      lrw[LIST_EQ_REWRITE,EL_REVERSE,PRE_SUB1,EL_APPEND1,EL_APPEND2,ADD1] >>
      Cases_on`x < LENGTH vs`>>
      lrw[EL_DROP,EL_REVERSE,PRE_SUB1,EL_APPEND1,EL_APPEND2,ADD1] >>
      `x = LENGTH vs` by DECIDE_TAC >>
      simp[] ) >>
    conj_tac >- (
      simp[BUTLASTN_APPEND1,BUTLASTN] >>
      simp[FILTER_APPEND,SUM_APPEND] ) >>
    pop_assum mp_tac >>
    simp[Once SWAP_REVERSE] ) >>
  metis_tac[])

(* TODO: move *)
val closed_under_menv_def = Define`
  closed_under_menv menv env s ⇔
    EVERY (closed menv) s ∧
    EVERY (closed menv) (MAP SND env) ∧
    EVERY (EVERY (closed menv) o MAP SND) (MAP SND menv)`

fun filter_asms P = POP_ASSUM_LIST (MAP_EVERY ASSUME_TAC o filter (P o concl))
fun contains tms tm = can (find_term (C mem tms)) tm

val err_to_Cerr = Define`
  (err_to_Cerr (Rraise Bind_error) = Craise CBind_excv) ∧
  (err_to_Cerr (Rraise Div_error) = Craise CDiv_excv) ∧
  (err_to_Cerr (Rraise (Int_error n)) = Craise (CLitv (IntLit n))) ∧
  (err_to_Cerr (Rtype_error) = Ctype_error) ∧
  (err_to_Cerr (Rtimeout_error) = Ctimeout_error)`
val _ = export_rewrites["err_to_Cerr_def"]

val err_bv_def = Define`
  (err_bv Div_error bv ⇔ bv = Block (block_tag+div_exc_cn) []) ∧
  (err_bv Bind_error bv ⇔ bv = Block (block_tag+bind_exc_cn) []) ∧
  (err_bv (Int_error n) bv ⇔ bv = Number n)`

val Cmap_result_Rerr = store_thm("Cmap_result_Rerr",
 ``Cmap_result f (Rerr err) = Cexc (err_to_Cerr err)``,
 Cases_on`err`>>simp[]>>Cases_on`e`>>simp[])

val env_renv_APPEND_suff = store_thm("env_renv_APPEND_suff",
  ``∀rd sz bs l1 l2 l3 l4.
    env_renv rd sz bs l1 l3 ∧ env_renv rd sz bs l2 l4 ⇒ env_renv rd sz bs (l1 ++ l2) (l3 ++ l4)``,
  rw[env_renv_def] >>
  match_mp_tac EVERY2_APPEND_suff >>
  simp[])

val env_renv_imp_incsz_many = store_thm("env_renv_imp_incsz_many",
  ``∀rd sz bs l1 l2 sz' bs' ls. env_renv rd sz bs l1 l2 ∧
    bs' = bs with stack := ls ++ bs.stack ∧
    sz' = sz + LENGTH ls ⇒
    env_renv rd sz' bs' l1 l2``,
  Induct_on`ls` >- simp[] >>
  simp[ADD1] >> rw[] >>
  REWRITE_TAC[ADD_ASSOC] >>
  match_mp_tac env_renv_imp_incsz >>
  qexists_tac`bs with stack := ls++bs.stack` >>
  simp[bc_state_component_equality] >>
  first_x_assum match_mp_tac >>
  qexists_tac`sz` >>
  qexists_tac`bs` >>
  simp[bc_state_component_equality])

val Cv_bv_l2a_mono_mp = MP_CANON (GEN_ALL (CONJUNCT1 (SPEC_ALL Cv_bv_l2a_mono)))

val env_renv_append_code = store_thm("env_renv_append_code",
  ``∀rd sz bs l1 l2 bs' ls. env_renv rd sz bs l1 l2  ∧ bs' = bs with code := bs.code ++ ls ⇒
     env_renv rd sz bs' l1 l2``,
  rw[env_renv_def] >>
  match_mp_tac (GEN_ALL (MP_CANON EVERY2_mono)) >>
  HINT_EXISTS_TAC >>
  simp[] >> rpt gen_tac >> BasicProvers.CASE_TAC >>
  strip_tac >>
  match_mp_tac Cv_bv_l2a_mono_mp >>
  qexists_tac `mk_pp rd bs` >>
  rw[] >> metis_tac[bc_find_loc_aux_append_code])

val print_envE_cons = store_thm("print_envE_cons",
  ``print_envE (x::xs) = print_envE[x]++print_envE xs``,
  rw[print_envE_def])

val print_v_ov = store_thm("print_v_ov",
  ``(∀v cm m sm mv. ov_to_string (Cv_to_ov m sm (v_to_Cv mv cm v)) = print_v v)
    ∧ (∀x:envE. T)
    ∧ (∀y:string#v. T)
    ∧ (∀vs:v list. T)``,
  ho_match_mp_tac(TypeBase.induction_of``:v``) >>
  simp[print_v_def,v_to_Cv_def,PrinterTheory.ov_to_string_def] >>
  Cases >> simp[PrinterTheory.ov_to_string_def,print_lit_def] >- (
    EVAL_TAC >> rw[] ) >>
  Cases_on`b`>>simp[PrinterTheory.ov_to_string_def,print_lit_def])

val print_bv_list_print_envE = store_thm("print_bv_list_print_envE",
  ``∀mv pp vars vs cm m Cvs bvs.
    EVERY2 syneq (MAP (v_to_Cv mv cm) vs) Cvs ∧ EVERY2 (Cv_bv pp) Cvs bvs ∧ LENGTH vars = LENGTH vs
    ⇒
    print_bv_list m vars bvs = REVERSE (print_envE (ZIP (vars,vs)))``,
  ntac 2 gen_tac >>
  Induct >- ( Cases >> simp[print_envE_def] ) >>
  qx_gen_tac`x`>>
  qx_gen_tac`ws`>>
  ntac 2 gen_tac >>
  map_every qx_gen_tac[`wvs`,`wbs`] >>
  strip_tac >>
  `∃v vs. ws = v::vs` by ( Cases_on`ws`>>fs[] ) >>
  `∃Cv Cvs. wvs = Cv::Cvs` by ( Cases_on`wvs`>>fs[EVERY2_EVERY] ) >>
  `∃bv bvs. wbs = bv::bvs` by ( Cases_on`wbs`>>fs[EVERY2_EVERY] ) >>
  rpt BasicProvers.VAR_EQ_TAC >>
  simp[Once print_envE_cons] >>
  first_x_assum(qspecl_then[`vs`,`cm`,`m`,`Cvs`,`bvs`]mp_tac) >>
  discharge_hyps >- fs[EVERY2_EVERY] >> rw[] >>
  rw[print_envE_def,print_bv_str_def] >>
  fs[EVERY2_EVERY] >>
  imp_res_tac Cv_bv_ov >>
  `bv_to_ov m bv = Cv_to_ov m (FST pp).sm (v_to_Cv mv cm v)` by
    metis_tac[syneq_ov] >>
  pop_assum SUBST1_TAC >>
  simp[print_v_ov])

val compile_fake_exp_val = store_thm("compile_fake_exp_val",
  ``∀pr rs vars expf menv tup cenv s env exp s' beh bdgs nl bc rd vv0 vv1 bc0 bs.
      evaluate T menv ((Short "",tup)::cenv) s env exp (s', beh) ∧
      FV exp ⊆ set (MAP (Short o FST) env) ∪ menv_dom menv ∧
      closed_under_menv menv env (SND s) ∧
      closed_under_cenv cenv menv env (SND s) ∧
      all_cns_exp exp ⊆ set (MAP FST ((Short "",tup)::cenv)) ∧
      (∀v. v ∈ env_range env ∨ MEM v (SND s) ⇒ all_locs v ⊆ count (LENGTH (SND s))) ∧
      env_rs menv cenv env rs rd s (bs with code := bc0) ∧
      ALL_DISTINCT vars ∧
      (compile_fake_exp pr rs vars expf = (rs.contab,bdgs,nl,REVERSE bc)) ∧
      (exp = expf (Con (Short "") (MAP (Var o Short) vars))) ∧
      (bs.code = bc0 ++ bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      IS_SOME bs.clock ∧
      ALL_DISTINCT (FILTER is_Label bc0) ∧
      EVERY (combin$C $< rs.rnext_label o dest_Label) (FILTER is_Label bc0)
      ⇒
      (∀vs. (beh = Rval (Conv (Short "") vs)) ∧ (LENGTH vars = LENGTH vs) ⇒
        ∃st rf rd' ck.
        let env' = ZIP(vars,vs) ++ env in
        let bs' = bs with <|pc := next_addr bs.inst_length (bc0 ++ bc); stack := st; refs := rf; clock := ck
                           ;output := if pr then REVERSE(print_envE (ZIP(vars,vs))) ++ bs.output else bs.output|> in
        let rs' = rs with <| renv := bdgs ++ rs.renv; rsz := rs.rsz + LENGTH bdgs; rnext_label := nl |> in
        bc_next^* bs bs' ∧
        env_rs menv cenv env' rs' rd' s' bs') ∧
      (∀err. (beh = Rerr (Rraise err)) ⇒
        ∃bv rf rd' ck.
        let bs' = bs with <|pc := 0; stack := bv::bs.stack; refs := rf; clock := ck|> in
        let rs' = rs with rnext_label := nl in
        bc_next^* bs bs' ∧
        err_bv err bv ∧
        env_rs menv cenv env rs' rd' s' (bs' with stack := bs.stack)) ∧
      ((beh = Rerr Rtimeout_error) ⇒
        ∃bs'. bc_next^* bs bs' ∧ (bs'.clock = SOME 0) ∧ bc_fetch bs' = SOME Tick)``,
  rpt gen_tac >>
  simp[compile_fake_exp_def,compile_Cexp_def,GSYM LEFT_FORALL_IMP_THM] >>
  simp[GSYM AND_IMP_INTRO] >>
  Q.PAT_ABBREV_TAC`Ce0 = exp_to_Cexp X (expf Y)` >>
  Q.PAT_ABBREV_TAC`p = label_closures Y X Ce0` >>
  PairCases_on`p`>>simp[]>> ntac 17 strip_tac >>
  qpat_assum`Abbrev(Ce0 = X)`mp_tac >>
  Q.PAT_ABBREV_TAC`exp' = expf X` >>
  `exp' = exp` by (
    rw[Abbr`exp'`] >>
    rpt AP_TERM_TAC >>
    REWRITE_TAC[GSYM MAP_APPEND] >>
    simp[MAP_EQ_f] ) >>
  qpat_assum`exp = X`kall_tac >>
  qpat_assum`Abbrev(exp' = X)`kall_tac >>
  pop_assum SUBST1_TAC >>
  strip_tac >>
  qmatch_abbrev_tac`G` >>
  fs[env_rs_def,LET_THM] >>
  qmatch_assum_abbrev_tac`LIST_REL syneq (env_to_Cenv mv cm env) Cenv` >>
  Cases_on`beh = Rerr Rtype_error`>>fs[]>-(fs[markerTheory.Abbrev_def]) >>
  qspecl_then[`T`,`menv`,`(Short"",tup)::cenv`,`s`,`env`,`exp`,`(s',beh)`] mp_tac (CONJUNCT1 exp_to_Cexp_thm1) >>
  simp[] >>
  discharge_hyps >- (
    fs[closed_under_menv_def] >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_MAP,closed_under_cenv_def,FORALL_PROD,EXISTS_PROD] >>
    metis_tac[SUBSET_DEF,IN_INSERT] ) >>
  disch_then (qspec_then `cm` mp_tac) >>
  discharge_hyps >- (
    fs[good_cmap_def,FAPPLY_FUPDATE_THM,Abbr`cm`] >>
    rw[] >>
    fs[SET_EQ_SUBSET,SUBSET_DEF,MEM_MAP,GSYM LEFT_FORALL_IMP_THM] >>
    qmatch_assum_rename_tac`MEM pp cenv`[] >>
    first_x_assum(qspec_then`FST pp`mp_tac) >>
    REWRITE_TAC[FLOOKUP_DEF] >>
    simp_tac std_ss [] >>
    discharge_hyps >- metis_tac[] >>
    metis_tac[]) >>
  disch_then(qx_choosel_then[`Cs'0`,`Cv0`]strip_assume_tac o SIMP_RULE(srw_ss())[EXISTS_PROD]) >>
  qspecl_then[`LENGTH rs.renv`,`rs.rnext_label`,`Ce0`]mp_tac(CONJUNCT1 label_closures_thm) >>
  discharge_hyps >- (
    simp[Abbr`Ce0`] >>
    match_mp_tac free_vars_exp_to_Cexp_matchable >>
    simp[] >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
      rw[] >> rfs[] >> res_tac >> fs[] >> metis_tac[]) >>
    fs[MAP_EQ_EVERY2] >>
    simp[SUBSET_DEF] ) >>
  simp[] >> strip_tac >>
  qpat_assum`X = REVERSE bc`mp_tac >>
  Q.PAT_ABBREV_TAC`cce = compile_code_env X Y Z` >>
  qpat_assum`Abbrev(cce = X)`mp_tac >>
  Q.PAT_ABBREV_TAC`s0 = X with out := Y` >>
  strip_tac >>
  qmatch_assum_abbrev_tac`Abbrev (cce = compile_code_env cmnv s0 p0)` >>
  qspecl_then[`LENGTH rs.renv`,`cmnv`,`s0`,`p0`]mp_tac compile_code_env_thm >>
  simp[] >>
  discharge_hyps >- (
    simp[ALL_DISTINCT_GENLIST,EVERY_GENLIST,Abbr`s0`] ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  qmatch_assum_rename_tac`set (free_vars Ce) ⊆ set (free_vars Ce0)`[] >>
  Q.PAT_ABBREV_TAC`renv:ctenv = MAP X Y` >>
  Q.PAT_ABBREV_TAC`sz = LENGTH rs.renv + X` >>
  qspecl_then[`cmnv`,`renv`,`TCNonTail`,`sz`,`cce`,`Ce`](Q.X_CHOOSE_THEN`bc1`strip_assume_tac)(CONJUNCT1 compile_append_out) >>
  Q.PAT_ABBREV_TAC`cmp = compile cmnv renv X Y Z A with out := U` >>
  Q.ISPECL_THEN[`vars`,`pr`,`cmp`,`0:num`]mp_tac compile_news_thm >>
  simp[] >> disch_then(Q.X_CHOOSE_THEN`c1`strip_assume_tac) >>
  simp[] >> rw[Abbr`s0`,Once SWAP_REVERSE] >>
  fs[Abbr`cmp`] >>
  `bc_fetch bs = SOME (PushPtr (Addr 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0` >> simp[] ) >>
  `ALL_DISTINCT (FILTER is_Label bs.code)` by (
    simp[FILTER_APPEND,SUM_APPEND,ADD1,FILTER_REVERSE,SUM_REVERSE,MAP_REVERSE] >>
    fs[GSYM FILTER_EQ_NIL,combinTheory.o_DEF] >>
    simp[ALL_DISTINCT_APPEND,ALL_DISTINCT_REVERSE,MEM_FILTER] >>
    fsrw_tac[DNF_ss][EVERY_MEM,between_def,FILTER_EQ_NIL,MEM_MAP,MEM_FILTER] >>
    fs[is_Label_rwt] >>
    fsrw_tac[DNF_ss][MEM_GENLIST] >>
    rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
  `bc_next bs (bump_pc bs with stack := CodePtr 0::bs.stack)` by (
    simp[bc_eval1_thm,bc_eval1_def,bc_find_loc_def] ) >>
  qmatch_assum_abbrev_tac`bc_next bs bs1` >>
  `bc_fetch bs1 = SOME PushExc` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0 ++ [PushPtr (Addr 0)]` >>
    simp[Abbr`bs1`,bump_pc_def,FILTER_APPEND,SUM_APPEND] ) >>
  `bc_next bs1 (bump_pc bs1 with <| stack := StackPtr (bs1.handler)::bs1.stack ; handler := LENGTH bs1.stack|>)` by (
    simp[bc_eval1_def,bc_eval1_thm] ) >>
  qmatch_assum_abbrev_tac`bc_next bs1 bs2` >>
  `bc_next^* bs bs2` by metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] >>
  qpat_assum`bc_next bs bs1`kall_tac >>
  qpat_assum`bc_next bs1 bs2`kall_tac >>
  qpat_assum`Abbrev(bs2 = X)`mp_tac >>
  qpat_assum`bs.code = X`(assume_tac o SYM) >>
  simp[bump_pc_def,Abbr`bs1`] >>
  strip_tac >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  last_x_assum(qspecl_then[`bs2`,`bc0 ++ [PushPtr(Addr 0);PushExc]`]mp_tac) >>
  qpat_assum`X = bs.code`(assume_tac o SYM) >>
  simp[Abbr`bs2`] >>
  discharge_hyps >- (
    simp[FILTER_APPEND,SUM_APPEND] >>
    simp[MEM_MAP,MEM_GENLIST,MEM_FILTER,GSYM LEFT_FORALL_IMP_THM,is_Label_rwt] >>
    fs[EVERY_FILTER,is_Label_rwt,EVERY_MEM] >>
    fsrw_tac[DNF_ss,ARITH_ss][] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  strip_tac >>
  qmatch_assum_abbrev_tac`bc_next bs2 bs1` >>
  rfs[] >>
  qmatch_assum_abbrev_tac`Cevaluate Cmenv0 (ck,Cs0) Cenv0 Ce0 ((ck',Cs'0),Cv0)` >>
  qspecl_then[`Cmenv0`,`ck,Cs0`,`Cenv0`,`Ce0`,`(ck',Cs'0),Cv0`]mp_tac(CONJUNCT1 Cevaluate_syneq) >> simp[] >>
  disch_then(qspecl_then[`$=`,`Cmenv`,`ck,Cs`,`Cenv`,`Ce`]mp_tac) >>
  `LENGTH Cenv0 = LENGTH env` by rw[Abbr`Cenv0`,env_to_Cenv_MAP] >>
  `LENGTH Cenv = LENGTH env` by fs[EVERY2_EVERY] >>
  simp[EXISTS_PROD] >>
  discharge_hyps >- (
    qpat_assum`LIST_REL syneq Cenv0 Cenv`mp_tac >>
    ntac 2 (pop_assum mp_tac) >>
    rfs[MAP_EQ_EVERY2] >>
    rpt (pop_assum kall_tac) >>
    simp[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >>
    simp[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM] ) >>
  disch_then(qx_choosel_then[`Cs'`,`Cv`]strip_assume_tac) >>
  qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`((ck',Cs'),Cv)`]mp_tac(CONJUNCT1 compile_val) >> simp[] >>
  disch_then(qspecl_then[`rd`,`cmnv`,`cce`,`renv`,`sz`,`LENGTH bs.stack`,`bs1`
    ,`bc0 ++ [PushPtr(Addr 0);PushExc]++c0`,`DROP (LENGTH bc0 + 2 + LENGTH c0) bs.code`
    ,`bc0 ++ [PushPtr(Addr 0);PushExc]++c0`,`REVERSE bc1`]mp_tac) >>
  simp[DROP_APPEND1,DROP_APPEND2,DROP_LENGTH_NIL_rwt] >>
  discharge_hyps >- (
    simp[Abbr`bs1`,DROP_APPEND1,DROP_APPEND2,DROP_LENGTH_NIL] >>
    conj_asm1_tac >- (
      simp[FILTER_APPEND,ALL_DISTINCT_APPEND] >>
      fsrw_tac[DNF_ss][EVERY_MEM,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
    rfs[MAP_EQ_EVERY2] >>
    conj_tac >- metis_tac[code_env_cd_append,APPEND_ASSOC] >>
    conj_tac >- metis_tac[code_env_cd_append,APPEND_ASSOC] >>
    conj_tac >- metis_tac[code_env_cd_append,APPEND_ASSOC] >>
    conj_tac >- (
      qunabbrev_tac`G` >>
      rfs[Cenv_bs_def,s_refs_def] >>
      Cases_on`bs.clock`>>fs[] ) >>
    conj_tac >- (
      match_mp_tac SUBSET_TRANS >>
      HINT_EXISTS_TAC >>
      simp[Abbr`Ce0`] >>
      match_mp_tac free_vars_exp_to_Cexp_matchable >>
      simp[] >>
      fs[Cenv_bs_def,EVERY2_EVERY,Abbr`renv`] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_FLAT] >>
      rw[] >> rfs[] >> res_tac >> fs[] >> metis_tac[]) >>
    conj_tac >- (
      simp[Abbr`sz`,Abbr`G`] >>
      SUBST1_TAC(DECIDE``2:num = 1 + 1``) >>
      REWRITE_TAC[ADD_ASSOC] >>
      Q.PAT_ABBREV_TAC`bs1:bc_state = X Y` >>
      match_mp_tac Cenv_bs_imp_incsz >>
      qexists_tac`bs1 with stack := TL bs1.stack` >>
      simp[Abbr`bs1`,bc_state_component_equality] >>
      Q.PAT_ABBREV_TAC`bs1:bc_state = X Y` >>
      REWRITE_TAC[ADD_ASSOC] >>
      match_mp_tac Cenv_bs_imp_incsz >>
      qexists_tac`bs1 with stack := TL bs1.stack` >>
      simp[Abbr`bs1`,bc_state_component_equality] >>
      Q.PAT_ABBREV_TAC`bs1:bc_state = X Y` >>
      match_mp_tac Cenv_bs_append_code >>
      qexists_tac`bs1 with code := bc0` >>
      simp[bc_state_component_equality,Abbr`bs1`] >>
      match_mp_tac Cenv_bs_with_irr >>
      qexists_tac`bs with code := bc0` >>
      simp[bc_state_component_equality]) >>
    qpat_assum`ALL_DISTINCT X`mp_tac >>
    qpat_assum`ALL_DISTINCT X`kall_tac >>
    strip_tac >>
    fsrw_tac[DNF_ss,ARITH_ss][EVERY_MEM,between_def,MEM_MAP,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,MEM_GENLIST] >>
    rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
  Cases_on`beh`>>fs[Abbr`G`]>- (
    Q.PAT_ABBREV_TAC`rsz = LENGTH rs.renv + X` >>
    disch_then(strip_assume_tac o CONJUNCT1) >>
    gen_tac >> ntac 2 strip_tac >> fs[] >>
    Q.PAT_ABBREV_TAC`mv:string |-> string list = X` >>
    Q.PAT_ABBREV_TAC`cocd = code_env_cd cmnv X` >>
    rpt BasicProvers.VAR_EQ_TAC >>
    Q.PAT_ABBREV_TAC`outp = if pr then X else bs.output` >>
    `∃u Cvs. (Cv = Cval(CConv u Cvs)) ∧ EVERY2 syneq (MAP (v_to_Cv mv cm) vs) Cvs` by (
      rator_x_assum`syneq`mp_tac >>
      simp[v_to_Cv_def,Once IntLangTheory.syneq_cases] >>
      simp_tac(srw_ss()++DNF_ss)[] >>
      simp[Abbr`cm`,vs_to_Cvs_MAP] >>
      gen_tac >> strip_tac >>
      qpat_assum`X Y Cv`mp_tac >>
      simp[Once IntLangTheory.syneq_cases] >>
      simp_tac(srw_ss()++DNF_ss)[] >>
      metis_tac[EVERY2_syneq_trans] ) >>
    qpat_assum`∀x. Y`mp_tac >>
    simp[Abbr`bs1`] >>
    simp_tac(srw_ss()++DNF_ss)[code_for_push_def,LET_THM] >>
    map_every qx_gen_tac[`rf`,`rd'`,`ck''`,`bv`] >> strip_tac >>
    qunabbrev_tac`bs2` >>
    qmatch_assum_abbrev_tac`bc_next^* bs1 bs2` >>
    rator_x_assum`Cv_bv`mp_tac >>
    simp[Once Cv_bv_cases] >>
    disch_then(Q.X_CHOOSE_THEN`bvs`strip_assume_tac) >>
    `bc_fetch bs2 = SOME PopExc` by (
      match_mp_tac bc_fetch_next_addr >>
      qexists_tac`TAKE (LENGTH bc0 + 2 + LENGTH c0 + LENGTH bc1) bs.code` >>
      simp[Abbr`bs2`,TAKE_APPEND1,TAKE_APPEND2,TAKE_LENGTH_ID_rwt] ) >>
    `bc_next bs2 (bump_pc bs2 with <| handler := bs.handler; stack := bv::CodePtr 0::bs.stack |>)` by (
      simp[bc_eval1_def,bc_eval1_thm,bump_pc_def] >>
      simp[Abbr`bs2`,EL_APPEND1,ADD1,EL_APPEND2] >>
      simp[bc_state_component_equality,TAKE_APPEND1,TAKE_APPEND2] ) >>
    qmatch_assum_abbrev_tac`bc_next bs2 bs2'` >>
    `bc_fetch bs2' = SOME (Stack (Pops 1))` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs2'`,bump_pc_def,Abbr`bs2`] >>
      qexists_tac`TAKE (LENGTH bc0 + 2 + LENGTH c0 + LENGTH bc1 + 1) bs.code` >>
      simp[TAKE_APPEND1,TAKE_APPEND2] >>
      simp[SUM_APPEND,FILTER_APPEND] ) >>
    `bc_next bs2' (bump_pc bs2' with <| stack := bv::bs.stack |>)` by (
      simp[bc_eval1_thm,bc_eval1_def] >>
      simp[bc_eval_stack_def,Abbr`bs2'`,bump_pc_def,Abbr`bs2`] ) >>
    qmatch_assum_abbrev_tac`bc_next bs2' bs2''` >>
    `bc_next^* bs1 bs2''` by metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] >>
    qpat_assum`bc_next bs2 X`kall_tac >>
    qpat_assum`bc_next bs2' X`kall_tac >>
    qpat_assum`Abbrev(bs2''=X)`mp_tac >>
    simp[Abbr`bs2'`,bump_pc_def,Abbr`bs2`] >>
    strip_tac >>
    qpat_assum`bc_fetch X = Y`kall_tac >>
    qpat_assum`bc_fetch X = Y`kall_tac >>
    qmatch_assum_rename_tac`Abbrev(bs2 = X)`["X"] >>
    last_x_assum(qspecl_then[`bs2 with code := TAKE (LENGTH bc0 + LENGTH bc1 + LENGTH c0 + 4 + LENGTH c1) bs.code`
                            ,`TAKE (LENGTH bc0 + LENGTH bc1 + LENGTH c0 + 4) bs.code`,`4+u`,`bvs`,`bs.stack`]mp_tac) >>
    discharge_hyps >- (
      simp[Abbr`bs2`,TAKE_APPEND1,TAKE_APPEND2,SUM_APPEND,FILTER_APPEND] >>
      fs[EVERY2_EVERY]) >>
    strip_tac >>
    qmatch_assum_abbrev_tac`bc_next^* bs2' bs3'` >>
    `bc_next^* (bs2' with code := bs.code) (bs3' with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs2'`,`bs3'`] >>
      simp[Abbr`bs2'`,Abbr`bs3'`,bc_state_component_equality] >>
      simp[TAKE_APPEND1,TAKE_APPEND2]) >>
    map_every qexists_tac[`TL bs3'.stack`,`rf`,`rd'`,`ck''`,`Cmenv`,`Cvs ++ Cenv`,`Cs'`] >>
    conj_tac >- (
      match_mp_tac (SIMP_RULE std_ss [transitive_def]RTC_TRANSITIVE) >>
      qmatch_assum_abbrev_tac`bc_next^* bs bs0` >>
      qmatch_assum_abbrev_tac`bc_next bs0' bs1` >>
      `bs0' = bs0` by (
        simp[Abbr`bs0`,Abbr`bs0'`,bc_state_component_equality] >>
        simp[SUM_APPEND,FILTER_APPEND] ) >>
      qexists_tac`bs2` >>
      conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] >>
      qmatch_assum_abbrev_tac`bc_next^* bs3 bs4` >>
      `bs3 = bs2` by (
        simp[Abbr`bs2`,Abbr`bs3`,bc_state_component_equality,Abbr`bs2'`] ) >>
      match_mp_tac (SIMP_RULE std_ss [transitive_def]RTC_TRANSITIVE) >>
      qexists_tac`bs4` >> pop_assum(SUBST1_TAC o SYM) >> simp[] >>
      simp[RTC_eq_NRC] >>
      qexists_tac`(SUC 0)` >>
      simp[NRC] >>
      simp[Abbr`bs4`,Abbr`bs3'`,Abbr`bs2`] >>
      qpat_assum`EVERY2 X Cvs bvs`mp_tac >>
      ntac 13 (pop_assum kall_tac) >> strip_tac >>
      Q.PAT_ABBREV_TAC`st:bc_value list = X ++ Y` >>
      simp[bc_eval1_thm] >>
      simp[TAKE_APPEND1,TAKE_APPEND2,REVERSE_APPEND] >>
      Q.PAT_ABBREV_TAC`cd = X ++ c1` >>
      qho_match_abbrev_tac`bc_eval1 bs6 = SOME z` >>
      `bc_fetch bs6 = SOME (Stack Pop)` by (
        match_mp_tac bc_fetch_next_addr >>
        qexists_tac`cd`>>simp[Abbr`bs6`] ) >>
      simp[bc_eval1_def,bump_pc_def] >>
      simp[Abbr`bs6`,bc_eval_stack_def] >>
      simp[Abbr`z`] >>
      simp[bc_state_component_equality,SUM_APPEND,FILTER_APPEND,Abbr`cd`,TAKE_APPEND1,TAKE_APPEND2] >>
      Cases_on`pr`>>simp[Abbr`outp`] >>
      match_mp_tac print_bv_list_print_envE >>
      metis_tac[]) >>
    qunabbrev_tac`bs3'` >>
    ntac 5 (pop_assum kall_tac) >>
    conj_tac >- metis_tac[EVERY2_syneq_trans] >>
    simp[] >>
    conj_tac >- (
      match_mp_tac EVERY2_APPEND_suff >>
      simp[] >>
      simp[env_to_Cenv_MAP] >>
      simp[GSYM MAP_MAP_o,MAP_ZIP] ) >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cv`]mp_tac(CONJUNCT1 Cevaluate_Clocs) >>
    simp[]>>simp_tac(srw_ss()++ETA_ss)[] >> strip_tac >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cv`]mp_tac(CONJUNCT1 Cevaluate_store_SUBSET) >>
    simp[] >> strip_tac >>
    conj_tac >- (
      match_mp_tac SUBSET_TRANS >>
      HINT_EXISTS_TAC >> simp[SUBSET_DEF] ) >>
    conj_tac >- (
      match_mp_tac SUBSET_TRANS >>
      qexists_tac`count (LENGTH Cs)` >>
      simp[SUBSET_DEF] ) >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cv`]mp_tac(CONJUNCT1 Cevaluate_all_vlabs) >>
    simp[] >> strip_tac >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cv`]mp_tac(CONJUNCT1 Cevaluate_vlabs) >>
    simp[SUBSET_DEF,Abbr`cocd`] >>
    SUBST1_TAC(prove(``bc0 ++ PushPtr (Lab l1)::PushExc::(c0 ++ REVERSE bc1) = bc0 ++ [PushPtr (Lab l1);PushExc] ++ c0 ++ REVERSE bc1``,simp[])) >>
    Q.PAT_ABBREV_TAC`cd:bc_inst list = X++Y` >>
    qmatch_assum_abbrev_tac`ALL_DISTINCT (FILTER is_Label cd)` >>
    strip_tac >>
    conj_tac >- (
      fs[MAP_EQ_EVERY2,EVERY_MEM] >>
      metis_tac[code_env_cd_append,APPEND_ASSOC] ) >>
    conj_tac >- (
      simp[vlabs_list_APPEND] >>
      fs[MAP_EQ_EVERY2,EVERY_MEM] >>
      metis_tac[code_env_cd_append,APPEND_ASSOC] ) >>
    conj_tac >- (
      fs[MAP_EQ_EVERY2,EVERY_MEM] >>
      metis_tac[code_env_cd_append,APPEND_ASSOC] ) >>
    conj_tac >- (
      simp[MAP_ZIP,MAP_GENLIST,combinTheory.o_DEF] >>
      match_mp_tac GENLIST_EL >>
      simp[] ) >>
    conj_tac >- (
      fs[markerTheory.Abbrev_def] >>
      simp[] ) >>
    qunabbrev_tac`cd` >>
    ntac 7 (pop_assum kall_tac) >>
    conj_asm1_tac >- fs[EVERY2_EVERY] >>
    Q.PAT_ABBREV_TAC`bsc:bc_state = X Y` >>
    match_mp_tac Cenv_bs_append_code >>
    qexists_tac`bsc with code := bc0 ++ [PushPtr(Addr 0); PushExc] ++ c0` >>
    simp[bc_state_component_equality,Abbr`bsc`] >>
    qmatch_abbrev_tac`Cenv_bs rd' Cmenv sCs' X cmnv Y Z Z bsc` >>
    qsuff_tac`Cenv_bs rd' Cmenv sCs' X cmnv Y Z Z (bsc with pc := next_addr bs.inst_length (bc0 ++ [PushPtr(Addr 0);PushExc] ++ c0 ++ REVERSE bc1))`
      >- (strip_tac >> match_mp_tac Cenv_bs_with_irr >> HINT_EXISTS_TAC >> simp[bc_state_component_equality]) >>
    rator_x_assum`Cenv_bs`mp_tac >>
    simp[Abbr`X`,Abbr`sz`,Abbr`Z`] >>
    simp[Cenv_bs_def,ADD1] >>
    strip_tac >>
    simp[CONJ_ASSOC] >>
    reverse conj_tac >- (
      fs[s_refs_def,good_rd_def,Abbr`bsc`] ) >>
    conj_tac >- (
      simp[Abbr`bsc`] >>
      fs[EVERY2_EVERY] >>
      simp[Abbr`Y`] >>
      match_mp_tac env_renv_APPEND_suff >>
      conj_tac >- (
        fs[env_renv_def,option_case_NONE_F] >>
        simp[EVERY2_MAP,CompilerLibTheory.el_check_def,REVERSE_APPEND] >>
        simp[EVERY2_EVERY,EVERY_MEM,FORALL_PROD,MEM_ZIP] >>
        simp[GSYM LEFT_FORALL_IMP_THM,GSYM AND_IMP_INTRO] >>
        simp[EL_REVERSE,EL_APPEND1,EL_APPEND2] >>
        rfs[EVERY2_EVERY,EVERY_MEM,MEM_ZIP,GSYM LEFT_FORALL_IMP_THM] ) >>
      match_mp_tac env_renv_imp_incsz_many >>
      rator_x_assum`Cenv_bs`mp_tac >>
      simp[Cenv_bs_def] >> strip_tac >>
      Q.PAT_ABBREV_TAC`bs6:bc_state = X Y` >>
      map_every qexists_tac[`rs.rsz`,`bs6 with stack := bs.stack`] >>
      simp[bc_state_component_equality,Abbr`bs6`] >>
      match_mp_tac (GEN_ALL env_renv_change_store) >>
      Q.PAT_ABBREV_TAC`bs6:bc_state = X Y` >>
      map_every qexists_tac[`sCs'`,`ck,Cs`,`rf`,`rd`,`ck''`,`bs6 with <| refs := bs.refs; clock := bs.clock |>`] >>
      simp[Abbr`bs6`] >>
      conj_tac >- (
        match_mp_tac env_renv_append_code >>
        Q.PAT_ABBREV_TAC`bs6:bc_state = X Y` >>
        qexists_tac`bs6 with code := bc0` >>
        simp[Abbr`bs6`,bc_state_component_equality] >>
        match_mp_tac env_renv_with_irr >>
        qexists_tac`bs with code := bc0` >> simp[] ) >>
      conj_tac >- (
        match_mp_tac s_refs_append_code >>
        Q.PAT_ABBREV_TAC`bs6:bc_state = X Y` >>
        qexists_tac`bs6 with code := bc0` >>
        simp[Abbr`bs6`,bc_state_component_equality] >>
        match_mp_tac s_refs_with_irr >>
        qexists_tac`bs with code := bc0` >> simp[] ) >>
      match_mp_tac s_refs_with_irr >>
      qmatch_assum_abbrev_tac`s_refs rd' sCs' bs6` >>
      qexists_tac`bs6` >> simp[Abbr`bs6`] ) >>
    Q.PAT_ABBREV_TAC`bs6:bc_state = X Z` >>
    match_mp_tac fmap_rel_env_renv_with_irr >>
    qexists_tac `bs6 with <| handler := rs.rsz + 1; output := bs.output |>` >>
    simp[Abbr`bs6`] >>
    match_mp_tac fmap_rel_env_renv_CTDec >>
    HINT_EXISTS_TAC >>
    simp[Abbr`bsc`,bc_state_component_equality] ) >>
  rfs[Cmap_result_Rerr] >>
  BasicProvers.VAR_EQ_TAC >>
  fs[] >>
  disch_then(qspec_then`TCNonTail`mp_tac) >>
  simp[Abbr`bs1`] >>
  strip_tac >>
  reverse conj_tac >- (
    strip_tac >> fs[] >>
    fs[Cmap_result_Rerr] >> rfs[] >>
    first_x_assum(qspec_then`bs.stack`mp_tac o CONV_RULE(RESORT_FORALL_CONV List.rev)) >>
    simp[] >>
    qpat_assum`bc_next^* bs X`mp_tac >>
    simp[SUM_APPEND,FILTER_APPEND,ADD1] >>
    qpat_assum`bc_next Y X`mp_tac >>
    simp[Abbr`bs2`,SUM_APPEND,FILTER_APPEND,ADD1] >>
    metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] ) >>
  gen_tac >> strip_tac >>
  rfs[Cmap_result_Rerr] >>
  BasicProvers.VAR_EQ_TAC >>
  BasicProvers.VAR_EQ_TAC >>
  `∃v. e'' = Craise v` by (
    Cases_on`e''`>>fs[]>>
    Cases_on`err`>>fs[] ) >>
  fs[] >>
  first_x_assum(qspec_then`[]`mp_tac) >>
  simp[ADD1] >>
  simp[code_for_return_def] >>
  disch_then(qx_choosel_then[`bv`,`rf`,`rd'`,`ck''`]strip_assume_tac) >>
  map_every qexists_tac[`bv`,`rf`,`rd'`,`ck''`] >>
  simp[CONJ_ASSOC] >>
  reverse conj_tac >- (
    map_every qexists_tac[`Cmenv`,`Cenv`,`Cs'`] >>
    simp[GSYM CONJ_ASSOC] >>
    conj_tac >- PROVE_TAC[EVERY2_syneq_trans] >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cexc (Craise v)`]mp_tac(CONJUNCT1 Cevaluate_Clocs) >>
    simp[] >> strip_tac >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cexc (Craise v)`]mp_tac(CONJUNCT1 Cevaluate_store_SUBSET) >>
    simp[] >> strip_tac >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      rw[] >> res_tac >> DECIDE_TAC ) >>
    conj_tac >- (
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      rw[] >> res_tac >> DECIDE_TAC ) >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cexc (Craise v)`]mp_tac(CONJUNCT1 Cevaluate_all_vlabs) >>
    simp[] >> strip_tac >>
    qspecl_then[`Cmenv`,`ck,Cs`,`Cenv`,`Ce`,`(ck',Cs'),Cexc (Craise v)`]mp_tac(CONJUNCT1 Cevaluate_vlabs) >>
    simp[] >> strip_tac >>
    qpat_assum`bs.code = X`(assume_tac o SYM) >> simp[] >>
    rfs[MAP_EQ_EVERY2] >>
    conj_tac >- (fsrw_tac[DNF_ss][SUBSET_DEF,EVERY_MEM] >> metis_tac[code_env_cd_append,APPEND_ASSOC]) >>
    conj_tac >- (fsrw_tac[DNF_ss][SUBSET_DEF,EVERY_MEM] >> metis_tac[code_env_cd_append,APPEND_ASSOC]) >>
    conj_tac >- (fsrw_tac[DNF_ss][SUBSET_DEF,EVERY_MEM] >> metis_tac[code_env_cd_append,APPEND_ASSOC]) >>
    match_mp_tac Cenv_bs_with_irr >>
    qexists_tac`bs with <| refs := rf; clock := ck''|>` >>
    simp[bc_state_component_equality] >>
    match_mp_tac Cenv_bs_append_code >>
    qmatch_assum_abbrev_tac`s_refs rd' sCs' bs'` >>
    qexists_tac`bs with <| code := bs'.code; refs := rf; clock := ck''|>` >>
    qpat_assum`X = bs.code`(assume_tac o SYM) >>
    simp[bc_state_component_equality,Abbr`bs'`] >>
    match_mp_tac Cenv_bs_change_store >>
    Q.PAT_ABBREV_TAC`cc = bc0 ++ X ++ c0` >>
    map_every qexists_tac[`rd`,`ck,Cs`,`bs with code := cc`] >>
    simp[bc_state_component_equality] >>
    conj_tac >- (
      match_mp_tac Cenv_bs_append_code >>
      qexists_tac`bs with code := bc0` >>
      simp[Abbr`cc`,bc_state_component_equality] ) >>
    match_mp_tac s_refs_with_irr >>
    HINT_EXISTS_TAC >> simp[] ) >>
  reverse conj_tac >- (
    qpat_assum`syneq X v`mp_tac >>
    rator_x_assum`Cexc_rel`mp_tac>>
    Cases_on`err`>>simp[err_bv_def,Once IntLangTheory.syneq_cases]>>
    rw[]>>fs[Once IntLangTheory.syneq_cases]>>
    rator_x_assum`Cv_bv`mp_tac>>
    rw[Once Cv_bv_cases]) >>
  qmatch_assum_abbrev_tac`bc_next^* bs bs1` >>
  qmatch_assum_abbrev_tac`bc_next bs2 bs3` >>
  qmatch_abbrev_tac`bc_next^* bs bs4` >>
  qsuff_tac`bs1 = bs2 ∧ bc_next^* bs3 bs4` >- metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] >>
  conj_tac >- (
    simp[Abbr`bs1`,Abbr`bs2`,bc_state_component_equality,SUM_APPEND,FILTER_APPEND] ) >>
  qmatch_assum_abbrev_tac`bc_next^* bs5 bs6` >>
  `bs3 = bs5` by (
    simp[Abbr`bs3`,Abbr`bs5`,bc_state_component_equality] ) >>
  qsuff_tac`bs6 = bs4` >- metis_tac[RTC_CASES1] >>
  simp[Abbr`bs6`,Abbr`bs4`,bc_state_component_equality])

(* TODO: move?*)
val FV_dec_def = Define`
  (FV_dec (Dlet p e) = FV (Mat e [(p,Lit ARB)])) ∧
  (FV_dec (Dletrec defs) = FV (Letrec defs (Lit ARB))) ∧
  (FV_dec (Dtype _) = {})`
val _ = export_rewrites["FV_dec_def"]

val FV_top_def = Define`
  (FV_top (Tdec d) = FV_dec d) ∧
  (FV_top (Tmod _ _ ds) = BIGUNION (IMAGE FV_dec (set ds)))`
val _ = export_rewrites["FV_top_def"]

val dec_cns_def = Define`
  (dec_cns (Dlet p e) = all_cns_pat p ∪ all_cns_exp e) ∧
  (dec_cns (Dletrec defs) = all_cns_defs defs) ∧
  (dec_cns (Dtype _) = {})`
val _ = export_rewrites["dec_cns_def"]

val top_cns_def = Define`
  (top_cns (Tdec d) = dec_cns d) ∧
  (top_cns (Tmod _ _ ds) = BIGUNION (IMAGE dec_cns (set ds)))`
val _ = export_rewrites["top_cns_def"]

val new_dec_cns_def = Define`
  (new_dec_cns (Dtype ts) = set (MAP FST (FLAT (MAP (SND o SND) ts)))) ∧
  (new_dec_cns _ = {})`
val _ = export_rewrites["new_dec_cns_def"]

val new_top_cns_def = Define`
  (new_top_cns (Tdec d) = new_dec_cns d) ∧
  (new_top_cns (Tmod _ _ ds) = BIGUNION (IMAGE new_dec_cns (set ds)))`
val _ = export_rewrites["new_top_cns_def"]

val pmatch_extend_cenv = store_thm("pmatch_extend_cenv",
  ``(∀(cenv:envC) s p v env id x. id ∉ set (MAP FST cenv) ∧ pmatch cenv s p v env ≠ Match_type_error
    ⇒ pmatch ((id,x)::cenv) s p v env = pmatch cenv s p v env) ∧
    (∀(cenv:envC) s ps vs env id x. id ∉ set (MAP FST cenv) ∧ pmatch_list cenv s ps vs env ≠ Match_type_error
    ⇒ pmatch_list ((id,x)::cenv) s ps vs env = pmatch_list cenv s ps vs env)``,
  ho_match_mp_tac pmatch_ind >>
  rw[pmatch_def] >> rw[] >>
  BasicProvers.CASE_TAC >> rw[] >> rpt (pop_assum mp_tac) >>
  TRY (BasicProvers.CASE_TAC >> rw[] >> rpt (pop_assum mp_tac)) >>
  TRY (BasicProvers.CASE_TAC >> rw[] >> rpt (pop_assum mp_tac)) >>
  TRY (BasicProvers.CASE_TAC) >> rw[] >>
  TRY (
    TRY (BasicProvers.CASE_TAC) >> rw[] >>
    imp_res_tac ALOOKUP_MEM >>
    fsrw_tac[DNF_ss][MEM_MAP,FORALL_PROD] >>
    metis_tac[]))

val evaluate_extend_cenv = store_thm("evaluate_extend_cenv",
  ``(∀ck menv (cenv:envC) cs env exp res. evaluate ck menv cenv cs env exp res ⇒
      ∀id x. (SND res ≠ Rerr Rtype_error) ∧ id ∉ set (MAP FST cenv) ⇒ evaluate ck menv ((id,x)::cenv) cs env exp res) ∧
    (∀ck menv (cenv:envC) cs env es res. evaluate_list ck menv cenv cs env es res ⇒
      ∀id x. (SND res ≠ Rerr Rtype_error) ∧ id ∉ set (MAP FST cenv) ⇒ evaluate_list ck menv ((id,x)::cenv) cs env es res) ∧
    (∀ck menv (cenv:envC) cs env v pes res. evaluate_match ck menv cenv cs env v pes res ⇒
      ∀id x. (SND res ≠ Rerr Rtype_error) ∧ id ∉ set (MAP FST cenv) ⇒ evaluate_match ck menv ((id,x)::cenv) cs env v pes res)``,
  ho_match_mp_tac evaluate_strongind >>
  rw[FORALL_PROD,EXISTS_PROD] >>
  TRY(Cases_on`cs`)>>TRY(Cases_on`cs'`)>>
  rw[Once evaluate_cases] >>
  fsrw_tac[DNF_ss][EXISTS_PROD,FORALL_PROD,MEM_MAP] >>
  TRY(metis_tac[])>>
  TRY(
    fs[SemanticPrimitivesTheory.do_con_check_def] >> rw[] >>
    Cases_on`ALOOKUP cenv cn`>>fs[] >>
    imp_res_tac ALOOKUP_MEM >>
    PairCases_on`x`>>fs[] >> metis_tac[]) >>
  Q.ISPECL_THEN[`cenv`,`s`,`p`,`v`,`env`,`id`]mp_tac(CONJUNCT1 pmatch_extend_cenv) >>
  simp[MEM_MAP,FORALL_PROD])

val evaluate_list_MAP_Var = store_thm("evaluate_list_MAP_Var",
  ``∀vs ck menv cenv s env. set vs ⊆ set (MAP FST env) ⇒ evaluate_list ck menv cenv s env (MAP (Var o Short) vs) (s,Rval (MAP (THE o ALOOKUP env) vs))``,
  Induct >> simp[Once evaluate_cases] >>
  rw[] >> rw[Once evaluate_cases,SemanticPrimitivesTheory.lookup_var_id_def] >>
  Cases_on`ALOOKUP env h`>>simp[] >>
  imp_res_tac ALOOKUP_FAILS >>
  fsrw_tac[DNF_ss][MEM_MAP,EXISTS_PROD])

(*
val env_rs_ALOOKUP_same = store_thm("env_rs_ALOOKUP_same",
  ``∀menv cenv env rs rd s bs env'.
    env_rs menv cenv env rs rd s bs ∧ (ALOOKUP env' = ALOOKUP env) ⇒
    env_rs menv cenv env' rs rd s bs``,
  simp[env_rs_def] >> rw[] >>
  REWRITE_TAC[GSYM FDOM_alist_to_fmap] >>
  pop_assum mp_tac >>
  REWRITE_TAC[CONJUNCT1(GSYM ALOOKUP_EQ_FLOOKUP)] >>
  REWRITE_TAC[EXTENSION] >>
  REWRITE_TAC[FUN_EQ_THM] >>
  REWRITE_TAC[FLOOKUP_DEF] >>
  metis_tac[optionTheory.NOT_SOME_NONE])

val ALOOKUP_APPEND_same = store_thm("ALOOKUP_APPEND_same",
  ``∀l1 l2 l. (ALOOKUP l1 = ALOOKUP l2) ==> ALOOKUP (l1 ++ l) = ALOOKUP (l2 ++ l)``,
  rw[ALOOKUP_APPEND,FUN_EQ_THM])

val ALOOKUP_ALL_DISTINCT_PERM_same = store_thm("ALOOKUP_ALL_DISTINCT_PERM_same",
  ``∀l1 l2. ALL_DISTINCT (MAP FST l1) ∧ PERM (MAP FST l1) (MAP FST l2) ∧ (set l1 = set l2) ⇒ (ALOOKUP l1 = ALOOKUP l2)``,
  simp[EXTENSION] >>
  rw[FUN_EQ_THM] >>
  Cases_on`ALOOKUP l2 x` >- (
    imp_res_tac ALOOKUP_FAILS >>
    imp_res_tac MEM_PERM >>
    fs[FORALL_PROD,MEM_MAP,EXISTS_PROD] >>
    metis_tac[ALOOKUP_FAILS] ) >>
  qmatch_assum_rename_tac`ALOOKUP l2 x = SOME p`[] >>
  imp_res_tac ALOOKUP_MEM >>
  `ALL_DISTINCT (MAP FST l2)` by (
    metis_tac[ALL_DISTINCT_PERM]) >>
  imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
  metis_tac[])

val ALL_DISTINCT_PERM_ALOOKUP_ZIP = store_thm("ALL_DISTINCT_PERM_ALOOKUP_ZIP",
  ``∀l1 l2 l3. ALL_DISTINCT (MAP FST l1) ∧ PERM (MAP FST l1) l2
    ⇒ (set l1 = set (ZIP (l2, MAP (THE o ALOOKUP (l1 ++ l3)) l2)))``,
  rw[EXTENSION,FORALL_PROD,EQ_IMP_THM] >- (
    qmatch_assum_rename_tac`MEM (x,y) l1`[] >>
    imp_res_tac PERM_LENGTH >> fs[] >>
    simp[MEM_ZIP] >>
    imp_res_tac MEM_PERM >>
    fs[MEM_MAP,EXISTS_PROD] >>
    `MEM x l2` by metis_tac[] >>
    `∃m. m < LENGTH l2 ∧ x = EL m l2` by metis_tac[MEM_EL] >>
    qexists_tac`m`>>simp[]>>
    simp[EL_MAP] >>
    imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
    rw[ALOOKUP_APPEND] ) >>
  qmatch_rename_tac`MEM (x,y) l1`[] >>
  imp_res_tac PERM_LENGTH >>
  fs[MEM_ZIP] >>
  simp[EL_MAP] >>
  imp_res_tac MEM_PERM >>
  fs[MEM_EL,GSYM LEFT_FORALL_IMP_THM] >>
  first_x_assum(qspec_then`n`mp_tac) >>
  discharge_hyps >- simp[] >>
  disch_then(Q.X_CHOOSE_THEN`m`strip_assume_tac) >>
  qexists_tac`m` >>
  simp[EL_MAP] >>
  Cases_on`EL m l1`>>simp[ALOOKUP_APPEND] >>
  BasicProvers.CASE_TAC >- (
    imp_res_tac ALOOKUP_FAILS >>
    metis_tac[MEM_EL] ) >>
  metis_tac[MEM_EL,ALOOKUP_ALL_DISTINCT_MEM,optionTheory.THE_DEF])
*)

val number_constructors_thm = store_thm("number_constructors_thm",
  ``∀mn cs ac. number_constructors mn cs ac =
    ((FST(FST ac) |++ GENLIST (λi. (mk_id mn (FST (EL i cs)), (SND(SND(FST ac)))+i)) (LENGTH cs)
     ,REVERSE (GENLIST (λi. ((SND(SND(FST ac)))+i,mk_id mn(FST(EL i cs)))) (LENGTH cs)) ++ (FST(SND(FST ac)))
     ,(SND(SND(FST ac))) + LENGTH cs)
    ,(REVERSE (MAP (combin$C STRCAT " = <constructor>\n" o id_to_string o mk_id mn o FST) cs))++SND ac)``,
  gen_tac >> Induct >- simp[number_constructors_def,FUPDATE_LIST_THM] >>
  qx_gen_tac`p` >> PairCases_on`p` >>
  qx_gen_tac`q` >> PairCases_on`q` >>
  simp[number_constructors_def] >>
  conj_tac >- (
    simp[GENLIST_CONS,FUPDATE_LIST_THM] >>
    AP_TERM_TAC >>
    simp[LIST_EQ_REWRITE] ) >>
  simp[GENLIST_CONS] >>
  simp[LIST_EQ_REWRITE])

val number_constructors_append = store_thm("number_constructors_append",
  ``∀l1 l2 mn ct. number_constructors mn (l1 ++ l2) ct = number_constructors mn l2 (number_constructors mn l1 ct)``,
  Induct >> simp[number_constructors_def] >>
  qx_gen_tac`p` >> PairCases_on`p` >>
  ntac 2 gen_tac >> qx_gen_tac`q` >> PairCases_on`q` >>
  simp[number_constructors_def])

val FOLDL_number_constructors_thm = store_thm("FOLDL_number_constructors_thm",
  ``∀tds mn ct. FOLDL (λct p. case p of (x,y,cs) => number_constructors mn cs ct) ct tds =
    number_constructors mn (FLAT (MAP (SND o SND) tds)) ct``,
  Induct >- (simp[number_constructors_thm,FUPDATE_LIST_THM]) >>
  simp[] >>
  qx_gen_tac`p` >> PairCases_on`p` >>
  simp[] >>
  simp[number_constructors_append])

val check_dup_ctors_ALL_DISTINCT = store_thm("check_dup_ctors_ALL_DISTINCT",
  ``check_dup_ctors menv cenv tds ⇒ ALL_DISTINCT (MAP FST (FLAT (MAP (SND o SND) tds)))``,
  simp[SemanticPrimitivesTheory.check_dup_ctors_def] >>
  rw[] >>
  qmatch_assum_abbrev_tac`ALL_DISTINCT l1` >>
  qmatch_abbrev_tac`ALL_DISTINCT l2` >>
  qsuff_tac`l1 = l2`>- PROVE_TAC[] >>
  unabbrev_all_tac >>
  rpt (pop_assum kall_tac) >>
  Induct_on`tds` >> simp[FORALL_PROD] >>
  Induct >> simp[FORALL_PROD])

val check_dup_ctors_NOT_MEM = store_thm("check_dup_ctors_NOT_MEM",
  ``check_dup_ctors mn cenv tds ∧ MEM e (MAP FST (FLAT (MAP (SND o SND) tds))) ⇒ ¬MEM (mk_id mn e) (MAP FST cenv)``,
  simp[SemanticPrimitivesTheory.check_dup_ctors_def] >>
  strip_tac >>
  qpat_assum`ALL_DISTINCT X`kall_tac >>
  Induct_on`tds` >> simp[] >>
  fs[FORALL_PROD,res_quanTheory.RES_FORALL] >>
  rw[] >- (
    fsrw_tac[DNF_ss][MEM_MAP] >>
    qmatch_assum_rename_tac`MEM a b`[] >>
    PairCases_on`a`>>fs[] >>
    res_tac >>
    imp_res_tac ALOOKUP_FAILS >>
    simp[FORALL_PROD] >>
    metis_tac[] ) >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  simp[] >> metis_tac[])

val FLAT_MAP_MAP_lemma = store_thm("FLAT_MAP_MAP_lemma",
  ``MAP FST (FLAT (MAP (λ(tvs,tn,condefs). (MAP (λ(conN,ts). (mk_id mn conN,LENGTH ts,mk_id mn tn)) condefs)) tds)) =
    MAP (mk_id mn o FST) (FLAT (MAP (SND o SND) tds))``,
  simp[MAP_FLAT,MAP_MAP_o,combinTheory.o_DEF,UNCURRY])

val pat_to_Cpat_SUBMAP = store_thm("pat_to_Cpat_SUBMAP",
  ``(∀p m m'. all_cns_pat p ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ⇒ (SND (pat_to_Cpat m' p) = SND (pat_to_Cpat m p))) ∧
    (∀ps m m'. all_cns_pats ps ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ⇒ (SND (pats_to_Cpats m' ps) = SND (pats_to_Cpats m ps)))``,
  ho_match_mp_tac(TypeBase.induction_of``:pat``)>>
  simp[ToIntLangTheory.pat_to_Cpat_def,UNCURRY,FLOOKUP_DEF] >>
  simp[pat_to_Cpat_cnmap] >>
  conj_tac >- rw[SUBMAP_DEF] >>
  rw[] >>
  first_x_assum match_mp_tac >>
  simp[pat_to_Cpat_cnmap] >>
  simp[FST_pat_to_Cpat_bvars])

val exp_to_Cexp_SUBMAP = store_thm("exp_to_Cexp_SUBMAP",
  ``(∀m exp m'. all_cns_exp exp ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ∧ (m'.mvars = m.mvars) ⇒ (exp_to_Cexp m' exp = exp_to_Cexp m exp)) ∧
    (∀m ds m'. all_cns_defs ds ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ∧ (m'.mvars = m.mvars) ⇒ (defs_to_Cdefs m' ds = defs_to_Cdefs m ds)) ∧
    (∀m pes m'. all_cns_pes pes ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ∧ (m'.mvars = m.mvars) ⇒ (pes_to_Cpes m' pes = pes_to_Cpes m pes)) ∧
    (∀m es m'. all_cns_list es ⊆ FDOM m.cnmap ∧ m.cnmap ⊑ m'.cnmap ∧ (m'.bvars = m.bvars) ∧ (m'.mvars = m.mvars) ⇒ (exps_to_Cexps m' es = exps_to_Cexps m es))``,
  ho_match_mp_tac exp_to_Cexp_ind >>
  simp[exp_to_Cexp_def] >>
  conj_tac >- rw[SUBMAP_DEF,FLOOKUP_DEF] >>
  simp[UNCURRY] >>
  simp[pat_to_Cpat_SUBMAP] >>
  rw[] >>
  first_x_assum (match_mp_tac o MP_CANON) >>
  simp[pat_to_Cpat_cnmap,FST_pat_to_Cpat_bvars] >>
  Cases_on`pat_to_Cpat m p`>>simp[])

val v_to_Cv_SUBMAP = store_thm("v_to_Cv_SUBMAP",
  ``(∀mv m v m'. all_cns v ⊆ (FDOM m) ∧ m ⊑ m' ⇒ v_to_Cv mv m' v = v_to_Cv mv m v) ∧
    (∀mv m vs m'. BIGUNION (IMAGE all_cns (set vs)) ⊆ FDOM m ∧ m ⊑ m' ⇒ vs_to_Cvs mv m' vs = vs_to_Cvs mv m vs) ∧
    (∀mv m env m'. BIGUNION (IMAGE all_cns (env_range env)) ⊆ FDOM m ∧ m ⊑ m' ⇒ env_to_Cenv mv m' env = env_to_Cenv mv m env)``,
  ho_match_mp_tac v_to_Cv_ind >> simp[v_to_Cv_def] >>
  conj_tac >- rw[SUBMAP_DEF,FLOOKUP_DEF] >>
  simp[exp_to_Cexp_SUBMAP] >>
  rw[] >> AP_TERM_TAC >>
  simp[exp_to_Cexp_SUBMAP])

val compile_fake_exp_contab = store_thm("compile_fake_exp_contab",
  ``(compile_fake_exp pr rs vs e = (ct,b,n,c)) ⇒ ct = rs.contab``,
  rw[compile_fake_exp_def,LET_THM])

val mk_id_inj = store_thm("mk_id_inj",
  ``mk_id mn n1 = mk_id mn n2 ⇒ n1 = n2``,
  rw[AstTheory.mk_id_def] >>
  BasicProvers.EVERY_CASE_TAC >> fs[])

val tac =
  rpt BasicProvers.VAR_EQ_TAC >>
  qmatch_abbrev_tac`env_rs menv cenv renv rs1 rd1 s1 bs1`>>
  qmatch_assum_abbrev_tac`env_rs menv cenv renv rs2 rd1 s1 bs2`>>
  `rs1 = rs2` by rw[Abbr`rs1`,Abbr`rs2`,compiler_state_component_equality]>>
  `bs1 = bs2` by (rw[Abbr`bs1`,Abbr`bs2`,bc_state_component_equality]>>fs[print_envC_def]) >>
  rw[]

val compile_dec_val = store_thm("compile_dec_val",
  ``∀mn menv cenv s env dec res. evaluate_dec mn menv cenv s env dec res ⇒
     ∃ck. ∀rs ct bdgs nl rd bc bs bc0.
      EVERY (closed menv) s ∧
      EVERY (closed menv) (MAP SND env) ∧
      EVERY (EVERY (closed menv) o MAP SND) (MAP SND menv) ∧
      FV_dec dec ⊆ set (MAP (Short o FST) env) ∪ menv_dom menv ∧
      ("" ∉ new_dec_cns dec) ∧
      (∀mn n. MEM (Long mn n) (MAP FST cenv) ⇒ MEM mn (MAP FST menv)) ∧
      closed_under_cenv cenv menv env s ∧
      closed_under_menv menv env s ∧
      dec_cns dec ⊆ set (MAP FST cenv) ∧
      (∀v. v ∈ env_range env ∨ MEM v s ⇒ all_locs v ⊆ count (LENGTH s)) ∧
      env_rs menv cenv env rs rd (ck,s) (bs with code := bc0) ∧
      (compile_dec mn rs dec = (ct,bdgs,nl,REVERSE bc)) ∧
      (bs.code = bc0 ++ bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      IS_SOME bs.clock ∧
      ALL_DISTINCT (FILTER is_Label bc0) ∧
      EVERY (combin$C $< rs.rnext_label o dest_Label) (FILTER is_Label bc0)
      ⇒
      case res of (s',Rval(cenv',env')) =>
        ∃st rf rd'.
        let bs' = bs with <|pc := next_addr bs.inst_length (bc0 ++ bc); stack := st; refs := rf; clock := SOME 0
                           ;output := if IS_NONE mn then REVERSE(print_envC cenv' ++ print_envE env')++bs.output else bs.output|> in
        let rs' = rs with <|contab := ct; renv := bdgs ++ rs.renv; rsz := rs.rsz + LENGTH bdgs; rnext_label := nl|> in
        bc_next^* bs bs' ∧
        env_rs menv (cenv'++cenv) (env'++env) rs' rd' (0,s') bs'
      | (s',Rerr(Rraise err)) =>
        ∃bv rf rd'.
        let bs' = bs with <|pc := 0; stack := bv::bs.stack; refs := rf; clock := SOME 0|> in
        let rs' = rs with <|rnext_label := nl|> in
        bc_next^*bs bs' ∧
        err_bv err bv ∧
        env_rs menv cenv env rs' rd' (0,s') (bs' with stack := bs.stack)
      | (s',_) => T``,
  ho_match_mp_tac evaluate_dec_ind >>
  strip_tac >- (
    rpt gen_tac >>
    simp[compile_dec_def] >>
    strip_tac >>
    `count' = 0` by metis_tac[big_unclocked] >> BasicProvers.VAR_EQ_TAC >>
    fs[big_clocked_unclocked_equiv] >>
    qexists_tac`count'` >>
    rpt gen_tac >> strip_tac >>
    qabbrev_tac`vars = pat_bindings p[]` >>
    qabbrev_tac`exp = Con (Short "") (MAP (Var o Short) vars)` >>
    `Short "" ∉ set (MAP FST cenv)` by ( fs[env_rs_def]) >>
    `evaluate T menv ((Short "",(LENGTH vars,ARB))::cenv) (count',s) env (Mat e [(p,exp)])
        ((0,s2),Rval (Conv (Short "") (MAP (THE o ALOOKUP (env' ++ env)) vars)))` by (
      simp[Once evaluate_cases] >>
      map_every qexists_tac[`v`,`0,s2`] >>
      conj_tac >- (
        match_mp_tac(MP_CANON (CONJUNCT1 evaluate_extend_cenv)) >> simp[] ) >>
      simp[Once evaluate_cases] >>
      disj1_tac >>
      imp_res_tac pmatch_extend_cenv >>
      first_x_assum(qspecl_then[`v`,`s2`,`p`,`emp`]mp_tac) >>
      simp[] >>
      fs[LibTheory.emp_def] >> strip_tac >>
      simp[Once pmatch_nil] >>
      simp[Once evaluate_cases,Abbr`exp`] >>
      simp[SemanticPrimitivesTheory.do_con_check_def] >>
      match_mp_tac evaluate_list_MAP_Var >>
      qspecl_then[`cenv`,`s2`,`p`,`v`,`[]`,`env'`,`menv`]mp_tac(CONJUNCT1 pmatch_closed) >>
      qspecl_then[`T`,`menv`,`cenv`,`count',s`,`env`,`e`,`((0,s2),Rval v)`]mp_tac(CONJUNCT1 evaluate_closed) >>
      simp[]) >>
    qmatch_assum_abbrev_tac`evaluate T menv ((Short "",tup)::cenv) (count',s) env Mexp ((0,s2),Rval (Conv (Short "") vs))` >>
    qspecl_then[`IS_NONE mn`,`rs`,`vars`,`λb. Mat e [(p,b)]`,`menv`,`tup`,`cenv`,`count',s`,`env`]mp_tac compile_fake_exp_val >>
    simp[] >>
    disch_then(qspecl_then[`0,s2`,`Rval (Conv (Short "") vs)`,`rd`,`bc0`,`bs`]mp_tac) >>
    simp[AND_IMP_INTRO] >>
    imp_res_tac compile_fake_exp_contab >>
    discharge_hyps >- (
      qunabbrev_tac`vars` >>
      fs[markerTheory.Abbrev_def,FV_list_MAP] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_FLAT,EXISTS_PROD,all_cns_list_MAP] >>
      metis_tac[] ) >>
    disch_then(qx_choosel_then[`st`,`rf`,`rd'`,`ck'`]strip_assume_tac) >>
    map_every qexists_tac[`st`,`rf`,`rd'`] >>
    `ck' = SOME 0` by (
      imp_res_tac RTC_bc_next_clock_less >>
      fs[env_rs_def,LET_THM,Cenv_bs_def,s_refs_def,OPTREL_def] >> fs[] >> rw[] ) >>
    simp[LibTheory.emp_def] >>
    `env' = ZIP (vars,vs)` by (
      qsuff_tac`MAP FST env' = vars ∧ MAP SND env' = vs` >- (
        simp[Once LIST_EQ_REWRITE,EL_MAP,GSYM AND_IMP_INTRO] >> strip_tac >> strip_tac >>
        lrw[LIST_EQ_REWRITE,EL_ZIP,EL_MAP] >>
        metis_tac[PAIR_EQ,FST,SND,LENGTH_MAP,pair_CASES] ) >>
      qspecl_then[`cenv`,`s2`,`p`,`v`,`[]`,`env'`,`menv`]mp_tac(CONJUNCT1 pmatch_closed) >>
      qspecl_then[`T`,`menv`,`cenv`,`count',s`,`env`,`e`,`((0,s2),Rval v)`]mp_tac(CONJUNCT1 evaluate_closed) >>
      fs[LibTheory.emp_def] >> rw[] >>
      simp[Abbr`vs`] >>
      simp[MAP_MAP_o,MAP_EQ_f,ALOOKUP_APPEND,FORALL_PROD] >>
      rw[] >>
      imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
      simp[] ) >>
    conj_tac >- (
      Cases_on`mn`>>fs[]>>simp[print_envC_def] ) >>
    tac) >>
  strip_tac >- (
    rpt gen_tac >>
    simp[compile_dec_def] >>
    strip_tac >>
    `count' = 0` by metis_tac[big_unclocked] >> BasicProvers.VAR_EQ_TAC >>
    fs[big_clocked_unclocked_equiv] >>
    qexists_tac`count'` >>
    rpt gen_tac >> strip_tac >>
    qabbrev_tac`vars = pat_bindings p[]` >>
    qabbrev_tac`exp = Con (Short "") (MAP (Var o Short) vars)` >>
    `Short "" ∉ set (MAP FST cenv)` by ( fs[env_rs_def]) >>
    `evaluate T menv ((Short "",(LENGTH vars,ARB))::cenv) (count',s) env (Mat e [(p,exp)])
        ((0,s2),Rerr (Rraise Bind_error))` by (
      simp[Once evaluate_cases] >>
      disj1_tac >>
      map_every qexists_tac[`v`,`0,s2`] >>
      conj_tac >- (
        match_mp_tac(MP_CANON (CONJUNCT1 evaluate_extend_cenv)) >> simp[] ) >>
      simp[Once evaluate_cases] >>
      disj2_tac >>
      simp[Once evaluate_cases] >>
      imp_res_tac pmatch_extend_cenv >>
      first_x_assum(qspecl_then[`v`,`s2`,`p`,`emp`]mp_tac) >>
      simp[] >>
      fs[LibTheory.emp_def] >> strip_tac >>
      simp[Once pmatch_nil]) >>
    qmatch_assum_abbrev_tac`evaluate T menv ((Short "",tup)::cenv) (count',s) env Mexp ((0,s2),Rerr (Rraise Bind_error))` >>
    qspecl_then[`IS_NONE mn`,`rs`,`pat_bindings p []`,`λb. Mat e [(p,b)]`,`menv`,`tup`,`cenv`,`count',s`,`env`]mp_tac compile_fake_exp_val >>
    simp[] >>
    REWRITE_TAC[GSYM MAP_APPEND] >>
    disch_then(qspecl_then[`0,s2`,`Rerr (Rraise Bind_error)`,`rd`,`bc0`,`bs`]mp_tac) >>
    simp[AND_IMP_INTRO] >>
    imp_res_tac compile_fake_exp_contab >>
    discharge_hyps >- (
      qunabbrev_tac`vars` >>
      fs[markerTheory.Abbrev_def,FV_list_MAP] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_FLAT,EXISTS_PROD,all_cns_list_MAP] >>
      metis_tac[] ) >>
    strip_tac >>
    `ck = SOME 0` by (
      imp_res_tac RTC_bc_next_clock_less >>
      fs[env_rs_def,LET_THM,Cenv_bs_def,s_refs_def,OPTREL_def] >> fs[] >> rw[] ) >>
    rw[] >>
    map_every qexists_tac[`bv`,`rf`,`rd''`] >>
    fsrw_tac[ARITH_ss][err_bv_def] ) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rpt gen_tac >>
    simp[compile_dec_def] >>
    strip_tac >>
    `count' = 0` by metis_tac[big_unclocked] >> BasicProvers.VAR_EQ_TAC >>
    fs[big_clocked_unclocked_equiv] >>
    qexists_tac`count'` >>
    rpt gen_tac >> strip_tac >>
    qabbrev_tac`vars = pat_bindings p[]` >>
    qabbrev_tac`exp = Con (Short "") (MAP (Var o Short) vars)` >>
    `Short "" ∉ set (MAP FST cenv)` by ( fs[env_rs_def]) >>
    Cases_on`err=Rtype_error`>>simp[]>>
    `evaluate T menv ((Short "",(LENGTH vars,ARB))::cenv) (count',s) env (Mat e [(p,exp)])
        ((0,s'),Rerr err)` by (
      simp[Once evaluate_cases] >>
      disj2_tac >>
      match_mp_tac(MP_CANON (CONJUNCT1 evaluate_extend_cenv)) >>
      simp[] ) >>
    qmatch_assum_abbrev_tac`evaluate T menv ((Short "",tup)::cenv) (count',s) env Mexp ((0,s'),Rerr err)` >>
    qspecl_then[`IS_NONE mn`,`rs`,`pat_bindings p []`,`λb. Mat e [(p,b)]`,`menv`,`tup`,`cenv`,`count',s`,`env`]mp_tac compile_fake_exp_val >>
    simp[] >>
    REWRITE_TAC[GSYM MAP_APPEND] >>
    disch_then(qspecl_then[`0,s'`,`Rerr err`,`rd`,`bc0`,`bs`]mp_tac) >>
    simp[AND_IMP_INTRO] >>
    imp_res_tac compile_fake_exp_contab >>
    discharge_hyps >- (
      qunabbrev_tac`vars` >>
      fs[markerTheory.Abbrev_def,FV_list_MAP] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_FLAT,EXISTS_PROD,all_cns_list_MAP] >>
      metis_tac[] ) >>
    Cases_on`err`>>simp[] >>
    strip_tac >>
    `ck = SOME 0` by (
      imp_res_tac RTC_bc_next_clock_less >>
      fs[env_rs_def,LET_THM,Cenv_bs_def,s_refs_def,OPTREL_def] >> fs[] >> rw[] ) >>
    rw[] >>
    map_every qexists_tac[`bv`,`rf`,`rd''`] >>
    simp[]) >>
  strip_tac >- (
    rpt gen_tac >>
    simp[compile_dec_def,FST_triple] >>
    strip_tac >>
    qexists_tac`0` >>
    rpt gen_tac >>
    Q.PAT_ABBREV_TAC`MFF:string list = MAP X funs` >>
    `MFF = MAP FST funs` by (
      rw[Once LIST_EQ_REWRITE,Abbr`MFF`,EL_MAP] >>
      BasicProvers.CASE_TAC ) >>
    pop_assum SUBST1_TAC >> qunabbrev_tac`MFF` >>
    strip_tac >>
    qabbrev_tac`exp = Con (Short "") (MAP (Var o Short) (MAP FST funs))` >>
    `Short "" ∉ set (MAP FST cenv)` by ( fs[env_rs_def]) >>
    `evaluate T menv ((Short "",(LENGTH funs,ARB))::cenv) (0,s) env (Letrec funs exp)
        ((0,s),Rval (Conv (Short "") (MAP (THE o (ALOOKUP (build_rec_env funs env env))) (MAP FST funs))))` by (
      simp[Once evaluate_cases,FST_triple] >>
      simp[Once evaluate_cases,Abbr`exp`] >>
      simp[SemanticPrimitivesTheory.do_con_check_def] >>
      REWRITE_TAC[GSYM MAP_APPEND] >>
      match_mp_tac evaluate_list_MAP_Var >>
      simp[build_rec_env_dom]) >>
    qmatch_assum_abbrev_tac`evaluate T menv ((Short "",tup)::cenv) (0,s) env Mexp ((0,s),Rval (Conv (Short "") vs))` >>
    qspecl_then[`IS_NONE mn`,`rs`,`MAP FST funs`,`λb. Letrec funs b`,`menv`,`tup`,`cenv`,`0,s`,`env`]mp_tac compile_fake_exp_val >>
    simp[] >>
    REWRITE_TAC[GSYM MAP_APPEND] >>
    disch_then(qspecl_then[`0,s`,`Rval (Conv (Short "") vs)`,`rd`,`bc0`,`bs`]mp_tac) >>
    simp[AND_IMP_INTRO] >>
    imp_res_tac compile_fake_exp_contab >>
    discharge_hyps >- (
      fs[markerTheory.Abbrev_def,FV_list_MAP,LET_THM] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_FLAT,EXISTS_PROD,all_cns_list_MAP] >>
      metis_tac[] ) >>
    disch_then(qx_choosel_then[`st`,`rf`,`rd'`,`ck`]strip_assume_tac) >>
    map_every qexists_tac[`st`,`rf`,`rd'`] >>
    `ck = SOME 0` by (
      imp_res_tac RTC_bc_next_clock_less >>
      fs[env_rs_def,LET_THM,Cenv_bs_def,s_refs_def,OPTREL_def] >> fs[] >> rw[] ) >>
    simp[LibTheory.emp_def] >>
    `build_rec_env funs env [] = ZIP (MAP FST funs,vs)` by (
      simp[build_rec_env_MAP,LIST_EQ_REWRITE,Abbr`vs`,EL_MAP,UNCURRY,EL_ZIP] >>
      simp[ALOOKUP_APPEND] >> rw[] >>
      Q.PAT_ABBREV_TAC`al:(string#v)list = MAP X funs` >>
      `MEM (FST (EL x funs), Recclosure env funs (FST (EL x funs))) al` by (
        simp[Abbr`al`,MEM_MAP,EXISTS_PROD] >>
        simp[MEM_EL] >>
        metis_tac[pair_CASES,FST] ) >>
      `ALL_DISTINCT (MAP FST al)` by (
        simp[Abbr`al`,MAP_MAP_o,combinTheory.o_DEF,UNCURRY] >>
        srw_tac[ETA_ss][] ) >>
      imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
      simp[]) >>
    conj_tac >- ( Cases_on`mn`>>fs[print_envC_def] ) >>
    simp[] >> tac ) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    simp[compile_dec_def] >>
    rpt gen_tac >> strip_tac >>
    qexists_tac`0` >>
    simp[Once SWAP_REVERSE] >>
    rpt gen_tac >> strip_tac >>
    map_every qexists_tac[`bs.stack`,`bs.refs`,`rd`] >>
    conj_tac >- (
      simp[RTC_eq_NRC] >>
      qexists_tac`0` >> simp[] >>
      simp[bc_state_component_equality,SUM_APPEND,FILTER_APPEND] >>
      fs[env_rs_def,Cenv_bs_def,s_refs_def,LET_THM] >>
      Cases_on`bs.clock`>>fs[]) >>
    fs[FOLDL_number_constructors_thm,SemanticPrimitivesTheory.build_tdefs_def,LibTheory.emp_def] >>
    fs[env_rs_def] >>
    conj_tac >- (
      fs[number_constructors_thm] >>
      qabbrev_tac`p = rs.contab` >>
      PairCases_on`p` >>
      fs[good_contab_def] >>
      fs[good_cmap_def,cmap_linv_def] >>
      conj_asm1_tac >- (
        simp[MAP_REVERSE,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND,MAP_GENLIST,ALL_DISTINCT_GENLIST] >>
        fsrw_tac[DNF_ss][EVERY_MEM] >>
        simp[MEM_GENLIST] >>
        rw[] >> spose_not_then strip_assume_tac >> res_tac >> simp[] ) >>
      conj_asm1_tac >- (
        simp[MAP_REVERSE,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND,MAP_GENLIST,ALL_DISTINCT_GENLIST] >>
        simp[MEM_GENLIST,MEM_MAP,FORALL_PROD] >>
        imp_res_tac check_dup_ctors_ALL_DISTINCT >>
        fs[EL_ALL_DISTINCT_EL_EQ,EL_MAP] >>
        conj_tac >- metis_tac[mk_id_inj] >>
        qsuff_tac`∀e. MEM e (MAP FST (FLAT (MAP (SND o SND) tds))) ⇒ ¬MEM (mk_id mn e) (MAP SND p1)` >- (
          simp[MEM_MAP] >>
          simp[MEM_EL,EL_MAP,GSYM LEFT_FORALL_IMP_THM] >>
          simp[FORALL_PROD] ) >>
        imp_res_tac check_dup_ctors_NOT_MEM >>
        qx_gen_tac`z` >> strip_tac >>
        first_x_assum(qspec_then`z`mp_tac) >>
        simp[] >>
        qpat_assum`X = FDOM p0`mp_tac >>
        simp[EXTENSION] >>
        rpt strip_tac >>
        fs[SUBSET_DEF] >>
        `mk_id mn z ∈ FDOM p0` by metis_tac[] >>
        qsuff_tac`¬(MEM (mk_id mn z) (MAP FST cenv) ∨ (mk_id mn z) = Short "")`>-metis_tac[]>>
        simp[] >>
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        fs[SemanticPrimitivesTheory.id_to_string_def] >>
        res_tac >> fs[] >> rw[] >> fs[] >> metis_tac[]) >>
      conj_asm1_tac >- (
        simp[EVERY_MAP,EVERY_REVERSE,EVERY_GENLIST] >>
        fs[EVERY_MAP,EVERY_MEM] >>
        rw[] >> res_tac >> simp[] ) >>
      conj_asm1_tac >- (
        simp[FDOM_FUPDATE_LIST] >>
        fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP,MEM_GENLIST,SemanticPrimitivesTheory.id_to_string_def] ) >>
      simp[FDOM_FUPDATE_LIST] >>
      gen_tac >> strip_tac >- (
        match_mp_tac ALOOKUP_ALL_DISTINCT_MEM >>
        fsrw_tac[ARITH_ss][] >>
        simp[MEM_GENLIST] >>
        res_tac >>
        imp_res_tac ALOOKUP_MEM >>
        disj2_tac >>
        qmatch_abbrev_tac`MEM (A,y) p1` >>
        qsuff_tac`A = p0 ' x`>-(simp[Abbr`A`] >> PROVE_TAC[]) >>
        simp[Abbr`A`] >>
        match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
        simp[MAP_GENLIST,MEM_GENLIST] >>
        gen_tac >>
        spose_not_then strip_assume_tac >>
        `p0 ' x < p2` by (
          fs[EVERY_MAP,EVERY_MEM] >>
          res_tac >> fs[] ) >>
        qunabbrev_tac`y` >>
        qmatch_assum_abbrev_tac`x = mk_id mn (FST (EL m ls))` >>
        qmatch_assum_abbrev_tac`x = mk_id mn z` >>
        `MEM z (MAP FST ls)` by metis_tac[MEM_MAP,MEM_EL] >>
        `mk_id mn z ∉ set (MAP FST cenv)` by metis_tac[check_dup_ctors_NOT_MEM] >>
        pop_assum mp_tac >>
        fs[EXTENSION] >>
        qsuff_tac`mk_id mn z ≠ Short ""`>-metis_tac[] >>
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        spose_not_then strip_assume_tac >>
        fs[SemanticPrimitivesTheory.id_to_string_def] ) >>
      match_mp_tac ALOOKUP_ALL_DISTINCT_MEM >>
      fsrw_tac[ARITH_ss][] >>
      simp[MEM_GENLIST] >>
      disj1_tac >>
      pop_assum mp_tac >>
      simp[MEM_MAP,MEM_GENLIST] >>
      strip_tac >>
      qexists_tac`i` >>
      simp[SemanticPrimitivesTheory.id_to_string_def] >>
      qmatch_abbrev_tac`((p0 |++ ls) ' k) = z` >>
      qho_match_abbrev_tac`P ((p0 |++ ls) ' k)` >>
      match_mp_tac FUPDATE_LIST_ALL_DISTINCT_APPLY_MEM >>
      simp[Abbr`P`,Abbr`ls`,MEM_GENLIST,Abbr`k`] >>
      reverse conj_tac >- metis_tac[] >>
      fsrw_tac[DNF_ss][MAP_REVERSE,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND] >>
      qmatch_abbrev_tac`ALL_DISTINCT ls` >>
      qmatch_assum_abbrev_tac`ALL_DISTINCT (MAP SND (GENLIST X Y))` >>
      `ls = (MAP SND (GENLIST X Y))` by (
        simp[Abbr`ls`,Abbr`X`,Abbr`Y`,MAP_MAP_o,MAP_GENLIST,combinTheory.o_DEF] ) >>
      pop_assum SUBST1_TAC >>
      simp[] ) >>
    conj_tac >- (
      fs[good_cmap_def] >>
      simp[number_constructors_thm] >>
      conj_asm1_tac >- (
        simp[ALL_DISTINCT_APPEND] >>
        conj_tac >- (
          imp_res_tac check_dup_ctors_ALL_DISTINCT >>
          qmatch_assum_abbrev_tac`ALL_DISTINCT ls2` >>
          simp[MAP_FLAT,MAP_MAP_o,combinTheory.o_DEF,UNCURRY] >>
          qmatch_abbrev_tac`ALL_DISTINCT ls` >>
          `ls = MAP (mk_id mn) ls2` by (
            simp[Abbr`ls`,Abbr`ls2`,MAP_GENLIST,MAP_MAP_o,MAP_FLAT] >>
            simp[combinTheory.o_DEF]) >>
          pop_assum SUBST1_TAC >>
          match_mp_tac ALL_DISTINCT_MAP_INJ >>
          simp[] >>
          metis_tac[mk_id_inj]) >>
        imp_res_tac check_dup_ctors_NOT_MEM >>
        pop_assum mp_tac >>
        simp_tac(srw_ss()++DNF_ss)[MEM_MAP,MEM_FLAT,EXISTS_PROD] >>
        metis_tac[] ) >>
      rpt gen_tac >>
      simp[FDOM_FUPDATE_LIST] >>
      Q.PAT_ABBREV_TAC`ls:((string id) list) = MAP FST (GENLIST X Y)` >>
      Q.PAT_ABBREV_TAC`al:((string id#num) list) = X` >>
      qabbrev_tac`p = rs.contab` >> PairCases_on`p`>>fs[] >>
      Q.PAT_ABBREV_TAC`ls3:((string id#num#string id) list) = FLAT (MAP X tds)` >>
      `∀x. MEM x ls3 ⇒ MEM (FST x) ls` by (
        gen_tac >> strip_tac >>
        `MEM (FST x) (MAP FST ls3)` by metis_tac[MEM_MAP] >>
        fs[Abbr`ls3`,FLAT_MAP_MAP_lemma] >>
        simp[Abbr`ls`,Abbr`al`] >>
        pop_assum mp_tac >>
        simp[MEM_MAP,MEM_GENLIST] >>
        simp[MEM_EL] >>
        strip_tac >> simp[] >>
        simp_tac(srw_ss()++DNF_ss)[] >>
        metis_tac[] ) >>
      `∀x. x ∈ FDOM p0 ⇒ (p0 |++ al) ' x = p0 ' x` by (
        gen_tac >> strip_tac >>
        match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
        simp[Abbr`al`,Abbr`ls`,MAP_GENLIST,MEM_GENLIST] >>
        imp_res_tac check_dup_ctors_NOT_MEM >>
        pop_assum mp_tac >>
        simp[MEM_MAP,GSYM LEFT_FORALL_IMP_THM] >>
        simp[Once MEM_EL,GSYM LEFT_FORALL_IMP_THM] >> strip_tac >>
        spose_not_then strip_assume_tac >>
        first_x_assum(qspec_then`m`mp_tac) >>
        simp[] >> fs[EXTENSION] >>
        Cases_on`MEM x (MAP FST cenv)` >- (
          fs[MEM_MAP] >> metis_tac[] ) >>
        `x = Short ""` by metis_tac[] >>
        qsuff_tac`F`>-rw[] >>
        qpat_assum`"" ∉ X`mp_tac >>
        simp[MEM_MAP] >>
        simp[MEM_EL] >>
        simp[EXISTS_PROD] >>
        CONV_TAC SWAP_EXISTS_CONV >>
        qexists_tac`m` >> simp[] >>
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        Cases_on`EL m (FLAT (MAP (SND o SND) tds))`>>fs[]) >>
      `ALL_DISTINCT ls` by (
        simp[Abbr`ls`,Abbr`al`] >>
        imp_res_tac check_dup_ctors_ALL_DISTINCT >>
        qmatch_assum_abbrev_tac`ALL_DISTINCT ls2` >>
        simp[MAP_FLAT,MAP_MAP_o,combinTheory.o_DEF,UNCURRY] >>
        qmatch_abbrev_tac`ALL_DISTINCT ls` >>
        `ls = MAP (mk_id mn) ls2` by (
          simp[Abbr`ls`,Abbr`ls2`,MAP_GENLIST,LIST_EQ_REWRITE,combinTheory.o_DEF,EL_MAP] ) >>
        pop_assum SUBST1_TAC >>
        match_mp_tac ALL_DISTINCT_MAP_INJ >>
        simp[] >> metis_tac[mk_id_inj] ) >>
      `∀x. MEM x cenv ⇒ (FST x) ∈ FDOM p0` by (
        fs[EXTENSION,MEM_MAP] >> metis_tac[] ) >>
      `∀k1 k2 v v. MEM (k1,v) al ∧ MEM (k2,v) al ⇒ k1 = k2` by (
        simp[Abbr`al`,MEM_GENLIST] >>
        rpt gen_tac >> strip_tac >> fs[] ) >>
      `∀x. MEM x ls ⇒ MEM (x, (p0 |++ al) ' x) al` by (
        simp[Abbr`ls`] >> gen_tac >> strip_tac >>
        qsuff_tac `(λv. MEM (x,v) al) ((p0 |++ al) ' x)` >- rw[] >>
        match_mp_tac FUPDATE_LIST_ALL_DISTINCT_APPLY_MEM >>
        fs[MEM_MAP,EXISTS_PROD] >> metis_tac[] ) >>
      `∀k v1 v2. MEM (k,v1) ls3 ∧ MEM (k,v2) ls3 ⇒ v1 = v2` by (
        fs[ALL_DISTINCT_APPEND] >>
        qpat_assum`ALL_DISTINCT (MAP_FST ls3)`mp_tac >>
        simp[EL_ALL_DISTINCT_EL_EQ] >>
        simp_tac std_ss [MEM_EL,EL_MAP] >>
        strip_tac >>
        simp_tac(srw_ss()++DNF_ss)[] >>
        ntac 3 gen_tac >>
        map_every qx_gen_tac[`n1`,`n2`] >> strip_tac >>
        first_x_assum(qspecl_then[`n1`,`n2`]mp_tac) >>
        rpt (qpat_assum`X = EL Y ls3`(mp_tac o SYM)) >>
        rw[] >> fs[] ) >>
      `∀x. MEM x ls ⇒ x ∉ FDOM p0` by (
        simp[Abbr`ls`,Abbr`al`,MEM_GENLIST,EXISTS_PROD,MEM_MAP] >>
        ntac 8 (pop_assum kall_tac) >>
        qmatch_assum_rename_tac`Abbrev((p0,w,n) = rs.contab)`[] >>
        imp_res_tac check_dup_ctors_NOT_MEM >>
        gen_tac >> strip_tac >>
        fs[EXTENSION] >>
        spose_not_then strip_assume_tac >>
        Cases_on`MEM x (MAP FST cenv)` >- (
          pop_assum mp_tac >> simp[] >>
          first_x_assum match_mp_tac >>
          simp[MEM_MAP,EXISTS_PROD] >>
          simp[MEM_EL] >>
          CONV_TAC SWAP_EXISTS_CONV >>
          qexists_tac`i`>>simp[] >>
          Cases_on`EL i (FLAT (MAP (SND o SND) tds))`>>simp[] ) >>
        `x = Short ""` by metis_tac[] >> fs[] >>
        Cases_on`mn`>>fs[AstTheory.mk_id_def]>>
        fs[MEM_MAP] >>
        fs[MEM_EL] >>
        metis_tac[] ) >>
      `∀x y z. MEM (x,y) al ∧ z ∈ FDOM p0 ⇒ y ≠ (p0 ' z)` by (
        simp[Abbr`al`,MEM_GENLIST] >>
        ntac 9 (pop_assum kall_tac) >>
        gen_tac >> spose_not_then strip_assume_tac >>
        fs[good_contab_def,cmap_linv_def,EVERY_MAP] >>
        res_tac >> imp_res_tac ALOOKUP_MEM >>
        fs[EVERY_MEM,MEM_MAP] >> res_tac >>
        fsrw_tac[ARITH_ss][] ) >>
      strip_tac >- (
        res_tac >> simp[] >>
        Cases_on`p1`>>Cases_on`p2`>>fs[] >>
        metis_tac[] )
      >- ( res_tac >> simp[] >> metis_tac[] )
      >- ( res_tac >> simp[] >> metis_tac[] ) >>
      metis_tac[] ) >>
    conj_tac >- (
      fs[EXTENSION,number_constructors_thm,FDOM_FUPDATE_LIST] >>
      qx_gen_tac`x` >>
      qabbrev_tac`p = rs.contab` >>
      PairCases_on`p` >> fs[] >>
      Cases_on`x=Short""`>-metis_tac[]>>simp[]>>
      Cases_on`MEM x (MAP FST cenv)`>-metis_tac[]>>simp[]>>
      Cases_on`x ∈ FDOM p0`>-metis_tac[]>>simp[]>>
      simp[MEM_MAP,MEM_GENLIST,MEM_FLAT,EXISTS_PROD,UNCURRY]>>
      simp_tac(srw_ss()++DNF_ss)[MEM_MAP,EXISTS_PROD]>>
      qmatch_abbrev_tac`A ⇔ B` >>
      qsuff_tac`A ⇔ ∃y. MEM y (FLAT (MAP (SND o SND) tds)) ∧ (x = mk_id mn (FST y))`>-metis_tac[MEM_EL]>>
      simp[Abbr`A`,Abbr`B`,MEM_FLAT,EXISTS_PROD,MEM_MAP] >>
      simp_tac(srw_ss()++DNF_ss)[EXISTS_PROD]>>
      metis_tac[] ) >>
    conj_tac >- (
      fsrw_tac[DNF_ss][MEM_MAP,MEM_FLAT,FORALL_PROD] >>
      Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
      metis_tac[] ) >>
    conj_tac >- (
      simp[number_constructors_thm] >>
      qabbrev_tac`p = rs.contab` >>
      PairCases_on`p` >> fs[] >>
      fs[FLOOKUP_DEF,FDOM_FUPDATE_LIST] >>
      qx_gen_tac`id` >>
      qmatch_abbrev_tac`(P ∨ Q) ∧ A ⇒ R` >>
      fs[good_contab_def,cmap_linv_def] >>
      qmatch_assum_abbrev_tac`Abbrev(A ⇔ (((p0 |++ ls) ' id) = ((p0 |++ ls) ' (Short ""))))` >>
      `MEM (p0 ' (Short ""), (Short "")) p1` by (
        match_mp_tac ALOOKUP_MEM >>
        first_x_assum match_mp_tac >>
        fs[EXTENSION] >> metis_tac[] ) >>
      `MEM (p0 ' (Short "")) (MAP FST p1)` by (simp[MEM_MAP,EXISTS_PROD] >> metis_tac[]) >>
      `p0 ' (Short "") < p2` by fs[EVERY_MEM] >>
      `(p0 |++ ls) ' (Short "") = p0 ' (Short "")` by (
        match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
        simp[Abbr`ls`,MEM_MAP,MEM_GENLIST,FORALL_PROD] >>
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        metis_tac[MEM_EL,LENGTH_MAP,MEM_MAP] ) >>
      `ALL_DISTINCT (MAP FST ls)` by (
        imp_res_tac check_dup_ctors_ALL_DISTINCT >>
        qmatch_assum_abbrev_tac`ALL_DISTINCT ls2` >>
        `MAP FST ls = MAP (mk_id mn) ls2` by (
          simp[Abbr`ls`,Abbr`ls2`,MAP_GENLIST,LIST_EQ_REWRITE,EL_MAP] ) >>
        pop_assum SUBST1_TAC >>
        match_mp_tac ALL_DISTINCT_MAP_INJ >>
        simp[] >> metis_tac[mk_id_inj] ) >>
      Cases_on`Q=T` >- (
        fs[Abbr`P`,Abbr`A`,Abbr`R`,Abbr`Q`] >> strip_tac >>
        spose_not_then strip_assume_tac >>
        `(λv. MEM v (MAP SND ls)) (p0 ' (Short ""))` by (
          qpat_assum`X = p0 ' Y`(SUBST1_TAC o SYM) >>
          match_mp_tac FUPDATE_LIST_ALL_DISTINCT_APPLY_MEM >>
          fs[MEM_MAP,EXISTS_PROD] >>
          metis_tac[] ) >>
        pop_assum mp_tac >>
        simp[Abbr`ls`,MEM_MAP,MEM_GENLIST,FORALL_PROD] ) >>
      fs[Abbr`P`,Abbr`Q`,Abbr`R`,Abbr`A`] >>
      strip_tac >>
      `(p0 |++ ls) ' id = p0 ' id` by (
        match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
        simp[] ) >>
      fs[] ) >>
    fs[LET_THM] >>
    map_every qexists_tac[`Cmenv`,`Cenv`,`Cs`] >>
    simp[] >>
    simp[number_constructors_thm] >>
    simp[CONJ_ASSOC] >>
    reverse conj_tac >- (
      match_mp_tac Cenv_bs_with_irr >>
      simp[] >> rfs[] >>
      HINT_EXISTS_TAC >>
      simp[] >>
      fs[env_rs_def,Cenv_bs_def,s_refs_def,LET_THM] >>
      Cases_on`bs.clock`>>fs[]) >>
    (*
    reverse conj_tac >- (
      rpt strip_tac >>
      match_mp_tac  code_env_cd_append >>
      simp[FILTER_APPEND] ) >>
    reverse conj_tac >- (
      rpt strip_tac >>
      match_mp_tac  code_env_cd_append >>
      simp[FILTER_APPEND] ) >>
    reverse conj_tac >- (
      rpt strip_tac >>
      match_mp_tac  code_env_cd_append >>
      simp[FILTER_APPEND] ) >>
    *)
    reverse conj_tac >- (
      match_mp_tac (GEN_ALL (MP_CANON fmap_rel_trans)) >>
      HINT_EXISTS_TAC >> simp[] >>
      conj_tac >- metis_tac[EVERY2_syneq_trans] >>
      simp[fmap_rel_def] >> gen_tac >> strip_tac >>
      qmatch_abbrev_tac`EVERY2 syneq ls1 ls2` >>
      qsuff_tac`ls1 = ls2`>-rw[] >>
      simp[Abbr`ls1`,Abbr`ls2`,MAP_EQ_f,env_to_Cenv_MAP] >>
      rw[] >>
      match_mp_tac(CONJUNCT1 v_to_Cv_SUBMAP)>>
      qabbrev_tac`p = rs.contab` >>
      PairCases_on`p`>>fs[closed_under_cenv_def] >>
      conj_tac >- (
        match_mp_tac SUBSET_TRANS >>
        qexists_tac`set (MAP FST cenv)` >>
        simp[] >> fs[EXTENSION,SUBSET_DEF] >>
        reverse conj_tac >- metis_tac[] >>
        fsrw_tac[DNF_ss][MEM_FLAT] >>
        Q.ISPECL_THEN[`menv`,`x`]mp_tac alist_to_fmap_FAPPLY_MEM >>
        simp[] >> strip_tac >>
        qx_gen_tac`z` >> strip_tac >>
        first_x_assum(qspecl_then[`SND e`,`z`,`MAP SND (alist_to_fmap menv ' x)`](match_mp_tac o MP_CANON)) >>
        simp[MEM_MAP,EXISTS_PROD] >>
        PairCases_on`e`>>fs[] >>
        PROVE_TAC[]) >>
      simp[SUBMAP_DEF,FDOM_FUPDATE_LIST] >> rw[] >>
      match_mp_tac EQ_SYM >>
      match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
      simp[MAP_GENLIST,combinTheory.o_DEF,MEM_GENLIST] >>
      imp_res_tac check_dup_ctors_NOT_MEM >>
      spose_not_then strip_assume_tac >>
      fsrw_tac[DNF_ss][MEM_EL,EL_MAP] >>
      first_x_assum(qspec_then`i`mp_tac) >>
      simp[combinTheory.o_DEF] >> fs[EXTENSION,MEM_EL] >>
      Cases_on`x' = Short ""` >- (
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        fs[] >> metis_tac[EL_MAP] ) >>
      metis_tac[EL_MAP] ) >>
    conj_tac >- (
      match_mp_tac EVERY2_syneq_trans >>
      qmatch_assum_abbrev_tac`EVERY2 syneq X Cs` >>
      qexists_tac`X` >>
      simp[Abbr`X`] >>
      qmatch_abbrev_tac`EVERY2 syneq ls1 ls2` >>
      qsuff_tac`ls1 = ls2`>-rw[] >>
      simp[Abbr`ls1`,Abbr`ls2`,MAP_EQ_f] >>
      rw[] >>
      match_mp_tac(CONJUNCT1 v_to_Cv_SUBMAP)>>
      qabbrev_tac`p = rs.contab` >>
      PairCases_on`p`>>fs[closed_under_cenv_def] >>
      conj_tac >- (
        match_mp_tac SUBSET_TRANS >>
        qexists_tac`set (MAP FST cenv)` >>
        simp[] >> fs[EXTENSION,SUBSET_DEF] >>
        metis_tac[] ) >>
      simp[SUBMAP_DEF,FDOM_FUPDATE_LIST] >> rw[] >>
      match_mp_tac EQ_SYM >>
      match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
      simp[MAP_GENLIST,combinTheory.o_DEF,MEM_GENLIST] >>
      imp_res_tac check_dup_ctors_NOT_MEM >>
      spose_not_then strip_assume_tac >>
      fsrw_tac[DNF_ss][MEM_EL,EL_MAP] >>
      first_x_assum(qspec_then`i`mp_tac) >>
      simp[combinTheory.o_DEF] >> fs[EXTENSION,MEM_EL] >>
      Cases_on`x = Short ""` >- (
        Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
        fs[] >> metis_tac[EL_MAP] ) >>
      metis_tac[] ) >>
    match_mp_tac EVERY2_syneq_trans >>
    qmatch_assum_abbrev_tac`LIST_REL syneq X Cenv` >>
    qexists_tac`X` >>
    simp[Abbr`X`] >>
    qmatch_abbrev_tac`EVERY2 syneq ls1 ls2` >>
    qsuff_tac`ls1 = ls2`>-rw[] >>
    simp[Abbr`ls1`,Abbr`ls2`,MAP_EQ_f,env_to_Cenv_MAP] >>
    rw[] >>
    match_mp_tac(CONJUNCT1 v_to_Cv_SUBMAP)>>
    qabbrev_tac`p = rs.contab` >>
    PairCases_on`p`>>fs[closed_under_cenv_def] >>
    conj_tac >- (
      match_mp_tac SUBSET_TRANS >>
      qexists_tac`set (MAP FST cenv)` >>
      simp[] >> fs[EXTENSION,SUBSET_DEF,MEM_MAP] >>
      fsrw_tac[DNF_ss][EXISTS_PROD,FORALL_PROD] >>
      reverse conj_tac >- (
        fs[EXTENSION,MEM_MAP,FORALL_PROD,EXISTS_PROD] >>
        metis_tac[] ) >>
      rw[] >>
      Cases_on`ALOOKUP env v`>>fs[]>-(
        imp_res_tac ALOOKUP_FAILS >>
        PairCases_on`e` >>
        res_tac >> fs[] >> metis_tac[] ) >>
      PairCases_on`e`>>fs[] >>
      imp_res_tac ALOOKUP_MEM >>
      metis_tac[] ) >>
    simp[SUBMAP_DEF,FDOM_FUPDATE_LIST] >> rw[] >>
    match_mp_tac EQ_SYM >>
    match_mp_tac FUPDATE_LIST_APPLY_NOT_MEM >>
    simp[MAP_GENLIST,combinTheory.o_DEF,MEM_GENLIST] >>
    imp_res_tac check_dup_ctors_NOT_MEM >>
    spose_not_then strip_assume_tac >>
    fsrw_tac[DNF_ss][MEM_EL,EL_MAP] >>
    first_x_assum(qspec_then`i`mp_tac) >>
    simp[combinTheory.o_DEF] >> fs[EXTENSION,MEM_EL] >>
    Cases_on`x = Short ""` >- (
      Cases_on`mn`>>fs[AstTheory.mk_id_def] >>
      fs[] >> metis_tac[EL_MAP] ) >>
    metis_tac[] ) >>
  strip_tac >- rw[])

val compile_top_thm = store_thm("compile_top_thm",
  ``∀menv cenv s env top res. evaluate_top menv cenv s env top res ⇒
     ∃ck. ∀rs rss rsf rd bc bs bc0.
      EVERY (closed menv) s ∧
      EVERY (closed menv) (MAP SND env) ∧
      EVERY (EVERY (closed menv) o MAP SND) (MAP SND menv) ∧
      FV_top top ⊆ set (MAP (Short o FST) env) ∪ menv_dom menv ∧
      "" ∉ new_top_cns top ∧
      (∀mn n. MEM (Long mn n) (MAP FST cenv) ⇒ MEM mn (MAP FST menv)) ∧
      closed_under_cenv cenv menv env s ∧
      closed_under_menv menv env s ∧
      top_cns top ⊆ set (MAP FST cenv) ∧
      (∀v. v ∈ env_range env ∨ MEM v s ⇒ all_locs v ⊆ count (LENGTH s)) ∧
      env_rs menv cenv env rs rd (ck,s) (bs with code := bc0) ∧
      (compile_top rs top = (rss,rsf,bc ++ [Stop])) ∧
      (bs.code = bc0 ++ bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      IS_SOME bs.clock ∧
      ALL_DISTINCT (FILTER is_Label bc0) ∧
      EVERY (combin$C $< rs.rnext_label o dest_Label) (FILTER is_Label bc0)
      ⇒
      case res of (s',Rval(menv',cenv',env')) =>
        ∃bs' rd'.
        bc_next^* bs bs' ∧
        bs'.pc = next_addr bs'.inst_length (bc0 ++ bc) ∧
        env_rs (menv'++menv) (cenv'++cenv) (env'++env) rss rd' (0,s') bs'
      | (s',Rerr(Rraise err)) =>
        ∃bv bs' rd'.
        bc_next^*bs bs' ∧
        bs'.stack = bv::bs.stack ∧
        bs'.pc = 0 ∧
        err_bv err bv ∧
        env_rs menv cenv env rsf rd' (0,s') (bs' with stack := bs.stack)
      | (s',_) => T``,
  ho_match_mp_tac evaluate_top_ind >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    imp_res_tac compile_dec_val >>
    pop_assum mp_tac >> simp[] >> strip_tac >>
    qexists_tac`ck` >> rpt gen_tac >> strip_tac >>
    fs[] >>
    first_x_assum(qspec_then`rs`mp_tac) >>
    fs[compile_top_def] >>
    qabbrev_tac`p = compile_dec NONE rs d` >>
    PairCases_on`p`>>fs[LET_THM] >>
    disch_then(qspecl_then[`rd`,`bc`,`bs`,`bc0`]mp_tac) >>
    simp[] >>
    discharge_hyps >- (
      simp[Once SWAP_REVERSE] >>
      metis_tac[] ) >>
    rw[] >>
    HINT_EXISTS_TAC >>
    rw[LibTheory.emp_def] >>
    simp[] >>
    metis_tac[] ) >>
  strip_tac >- (
    simp[] >>
    rpt gen_tac >> strip_tac >>
    imp_res_tac compile_dec_val >>
    pop_assum mp_tac >> simp[] >> strip_tac >>
    qexists_tac`ck` >> rpt gen_tac >> strip_tac >>
    fs[] >>
    Cases_on`err`>>fs[] >>
    first_x_assum(qspec_then`rs`mp_tac) >>
    fs[compile_top_def] >>
    qabbrev_tac`p = compile_dec NONE rs d` >>
    PairCases_on`p`>>fs[LET_THM] >>
    disch_then(qspecl_then[`rd`,`bc`,`bs`,`bc0`]mp_tac) >>
    simp[] >>
    discharge_hyps >- (
      simp[Once SWAP_REVERSE] >>
      metis_tac[] ) >>
    rw[] >>
    HINT_EXISTS_TAC >>
    HINT_EXISTS_TAC >>
    rw[] >>
    HINT_EXISTS_TAC >>
    simp[]) >>
  strip_tac >- (
    simp[] >>
    cheat ) >>
  strip_tac >- (
    simp[] >>
    cheat ) >>
  simp[])

val _ = export_theory()
