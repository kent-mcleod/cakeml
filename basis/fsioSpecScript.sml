open preamble
     ml_translatorTheory ml_translatorLib ml_progLib
     cfTacticsBaseLib cfTacticsLib basisFunctionsLib
     mlstringTheory fsFFITheory fsFFIProofTheory
     cfLetAutoLib cfLetAutoTheory cfHeapsBaseTheory
     mlw8arrayProgTheory mlstringProgTheory cfMainTheory
     mlarrayProgTheory cfHeapsTheory fsioConstantsProgTheory fsioProgTheory

val _ = new_theory"fsioSpec";

val _ = translation_extends "fsioProg";
val _ = monadsyntax.add_monadsyntax();

val basis_st = get_ml_prog_state;

(* TODO: move *)
val LDROP_NONE_LFINITE = Q.store_thm("LDROP_NONE_LFINITE",
  `LDROP k l = NONE ⇒ LFINITE l`,
  cases_on`LFINITE l` >> fs[NOT_LFINITE_DROP,NOT_SOME_NONE] >>
  `∃ v. LDROP k l = SOME v` by fs[NOT_LFINITE_DROP] >> fs[]);

val THE_LDROP_comm = Q.store_thm("THE_LDROP_comm",
 `!ll k1 k2. ¬ LFINITE ll ==>
    THE (LDROP k2 (THE (LDROP k1 ll))) =
    THE (LDROP k1 (THE (LDROP k2 ll)))`,
    rw[] >>
    `LDROP (k1+k2) ll = LDROP (k2 + k1) ll` by fs[] >>
    fs[LDROP_ADD] >>
    NTAC 2 (full_case_tac >- imp_res_tac LDROP_NONE_LFINITE) >> fs[])

val TAKE_TAKE_MIN = Q.store_thm("TAKE_TAKE_MIN",
  `!m n. TAKE n (TAKE m l) = TAKE (MIN n m) l`,
  induct_on`l` >> rw[] >>
  cases_on`m` >> cases_on`n` >> fs[MIN_DEF] >> CASE_TAC >> fs[]);

val SPLITP_TAKE_DROP = Q.store_thm("SPLITP_TAKE_DROP",
 `!P i l. EVERY ($~ ∘ P) (TAKE i l) ==>
  P (EL i l) ==>
  SPLITP P l = (TAKE i l, DROP i l)`,
  Induct_on`l` >> rw[SPLITP] >> Cases_on`i` >> fs[] >>
  res_tac >> fs[FST,SND]);

val SND_SPLITP_DROP = Q.store_thm("SND_SPLITP_DROP",
 `!P n l. EVERY ($~ o P) (TAKE n l) ==>
   SND (SPLITP P (DROP n l)) = SND (SPLITP P l)`,
 Induct_on`n` >> rw[SPLITP] >> cases_on`l` >> fs[SPLITP]);

val FST_SPLITP_DROP = Q.store_thm("FST_SPLITP_DROP",
 `!P n l. EVERY ($~ o P) (TAKE n l) ==>
   FST (SPLITP P l) = (TAKE n l) ++ FST (SPLITP P (DROP n l))`,
 Induct_on`n` >> rw[SPLITP] >> cases_on`l` >>
 PURE_REWRITE_TAC[DROP_def,TAKE_def,APPEND] >> simp[] >>
 fs[SPLITP]);

val splitlines_CONS_FST_SPLITP = Q.store_thm("splitlines_CONS_FST_SPLITP",
  `splitlines ls = ln::lns ⇒ FST (SPLITP ($= #"\n") ls) = ln`,
  rw[splitlines_def]
  \\ Cases_on`ls` \\ fs[FIELDS_def]
  \\ TRY pairarg_tac \\ fs[] \\ rw[] \\ fs[]
  \\ every_case_tac \\ fs[] \\ rw[] \\ fs[NULL_EQ]
  \\ qmatch_assum_abbrev_tac`FRONT (x::y) = _`
  \\ Cases_on`y` \\ fs[]);

val STRCAT_eq = Q.store_thm("STRCAT_eq",
 `∀ x1 x2 y1 y2. LENGTH x1 = LENGTH x2 ∧ x1 ++ y1 = x2 ++ y2 ⇒
    (x1 = x2 ∧ y1 = y2)`,
  induct_on`x1` >> fs[] >> cases_on`x2` >> fs[] >> metis_tac[]);

val A_DELKEY_ALIST_FUPDKEY_comm = Q.store_thm("A_DELKEY_ALIST_FUPDKEY_comm",
 `!ls f x y. x <> y ==>
  A_DELKEY x (ALIST_FUPDKEY y f ls) = (ALIST_FUPDKEY y f (A_DELKEY x ls))`,
  Induct >>  rw[A_DELKEY_def,ALIST_FUPDKEY_def] >>
  cases_on`h` >> fs[ALIST_FUPDKEY_def] >> TRY CASE_TAC >> fs[A_DELKEY_def]);

val insert_atI_insert_atI = Q.store_thm("insert_atI_insert_atI",
  `pos2 = pos1 + LENGTH c1 ==>
    insert_atI c2 pos2 (insert_atI c1 pos1 l) = insert_atI (c1 ++ c2) pos1 l`,
    rw[insert_atI_def,TAKE_SUM,TAKE_APPEND,LENGTH_TAKE_EQ,LENGTH_DROP,
       GSYM DROP_DROP_T,DROP_LENGTH_TOO_LONG,DROP_LENGTH_NIL_rwt]
    >> fs[DROP_LENGTH_NIL_rwt,LENGTH_TAKE,DROP_APPEND1,TAKE_APPEND,TAKE_TAKE,
       DROP_DROP_T,DROP_APPEND2,TAKE_LENGTH_TOO_LONG,TAKE_SUM,LENGTH_DROP]);

val option_case_eq = prove_case_eq_thm{nchotomy=option_nchotomy,case_def=option_case_def};

val WORD_UNICITY_R = Q.store_thm("WORD_UNICITY_R[xlet_auto_match]",
`!f fv fv'. WORD (f :word8) fv ==> (WORD f fv' <=> fv' = fv)`, fs[WORD_def]);

val WORD_UNICITY_L = Q.store_thm("WORD_UNICITY_L[xlet_auto_match]",
`!f f' fv. WORD (f :word8) fv ==> (WORD f' fv <=> f = f')`, fs[WORD_def]);

val n2w_UNICITY = Q.store_thm("n2w_UNICITY[xlet_auto_match]",
 `!n1 n2.n1 <= 255 ==> ((n2w n1 :word8 = n2w n2 /\ n2 <= 255) <=> n1 = n2)`,
 rw[] >> eq_tac >> fs[])

val WORD_n2w_UNICITY_L = Q.store_thm("WORD_n2w_UNICITY[xlet_auto_match]",
 `!n1 n2 f. n1 <= 255 /\ WORD (n2w n1 :word8) f ==>
   (WORD (n2w n2 :word8) f /\ n2 <= 255 <=> n1 = n2)`,
 rw[] >> eq_tac >> rw[] >> imp_res_tac WORD_UNICITY_L >>
`n1 MOD 256 = n1` by fs[] >> `n2 MOD 256 = n2` by fs[] >> fs[])

val get_file_content_numchars = Q.store_thm("get_file_content_numchars",
 `!fs fd c p. get_file_content fs fd =
              get_file_content (fs with numchars := ll) fd`,
 fs[get_file_content_def]);

val eof_numchars = Q.store_thm("eof_numchars[simp]",
  `eof fd (fs with numchars := ll) = eof fd fs`,
  rw[eof_def]);

val bumpFD_numchars = Q.store_thm("bumpFD_numchars",
 `!fs fd n ll. bumpFD fd (fs with numchars := ll) n =
        (bumpFD fd fs n) with numchars := THE (LTL ll)`,
    fs[bumpFD_def]);

val STD_streams_numchars = Q.store_thm("STD_streams_numchars",
 `!fs ll. STD_streams fs = STD_streams (fs with numchars := ll)`,
 fs[STD_streams_def]);

val STDIO_numchars = Q.store_thm("STDIO_numchars",
  `STDIO (fs with numchars := x) = STDIO fs`,
  rw[STDIO_def,GSYM STD_streams_numchars]);

val openFileFS_numchars = Q.store_thm("openFileFS_numchars",
 `!s fs k. (openFileFS s fs k).numchars = fs.numchars`,
  rw[] >> EVAL_TAC >> rpt(CASE_TAC >> fs[IO_fs_component_equality]));

val wfFS_numchars = Q.store_thm("wfFS_numchars",
 `!fs ll. wfFS fs ==> ¬LFINITE ll ==>
          always (eventually (λll. ∃k. LHD ll = SOME k ∧ k ≠ 0)) ll ==>
          wfFS (fs with numchars := ll)`,
 fs[wfFS_def,liveFS_def,live_numchars_def]);

val wfFS_LTL = Q.store_thm("wfFS_LTL",
 `!fs ll. wfFS (fs with numchars := ll) ==>
          wfFS (fs with numchars := THE (LTL ll))`,
 rw[wfFS_def,liveFS_def,live_numchars_def] >> cases_on `ll` >> fs[LDROP_1] >>
 imp_res_tac always_thm);

val bumpFD_o = Q.store_thm("bumpFD_o",
 `!fs fd n1 n2.
    bumpFD fd (bumpFD fd fs n1) n2 =
    bumpFD fd fs (n1 + n2) with numchars := THE (LTL (THE (LTL fs.numchars)))`,
 rw[bumpFD_def] >> cases_on`fs` >> fs[IO_fs_component_equality] >>
 fs[ALIST_FUPDKEY_o] >> irule ALIST_FUPDKEY_eq >> rw[] >> cases_on `v` >> fs[])

val bumpFD_0 = Q.store_thm("bumpFD_0",
  `bumpFD fd fs 0 = fs with numchars := THE (LTL fs.numchars)`,
  rw[bumpFD_def,IO_fs_component_equality] \\
  match_mp_tac ALIST_FUPDKEY_unchanged \\
  simp[FORALL_PROD]);

val get_file_content_eof = Q.store_thm("get_file_content_eof",
  `get_file_content fs fd = SOME (content,pos) ⇒ eof fd fs = SOME (¬(pos < LENGTH content))`,
  rw[get_file_content_def,eof_def]
  \\ pairarg_tac \\ fs[]);

val _ = temp_clear_overloads_on"STRCAT";
val _ = temp_clear_overloads_on"STRLEN";
val _ = temp_clear_overloads_on"STRING";

val lineFD_def = Define`
  lineFD fs fd = do
    (content, pos) <- get_file_content fs fd;
    assert (pos < LENGTH content);
    let (l,r) = SPLITP ((=)#"\n") (DROP pos content) in
      SOME(l++"\n") od`;

(* like bumpFD but leave numchars *)
val forwardFD_def = Define`
  forwardFD fs fd n =
    fs with infds updated_by ALIST_FUPDKEY fd (I ## (+) n)`;

val forwardFD_const = Q.store_thm("forwardFD_const[simp]",
  `(forwardFD fs fd n).files = fs.files ∧
   (forwardFD fs fd n).numchars = fs.numchars`,
  rw[forwardFD_def]);

val forwardFD_o = Q.store_thm("forwardFD_o",
  `forwardFD (forwardFD fs fd n) fd m = forwardFD fs fd (n+m)`,
  rw[forwardFD_def,IO_fs_component_equality,ALIST_FUPDKEY_o]
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ simp[FUN_EQ_THM,FORALL_PROD]);

val forwardFD_0 = Q.store_thm("forwardFD_0[simp]",
  `forwardFD fs fd 0 = fs`,
  rw[forwardFD_def,IO_fs_component_equality]
  \\ match_mp_tac ALIST_FUPDKEY_unchanged
  \\ simp[FORALL_PROD]);

val forwardFD_numchars = Q.store_thm("forwardFD_numchars",
  `forwardFD (fs with numchars := ll) fd n = forwardFD fs fd n with numchars := ll`,
  rw[forwardFD_def]);

val liveFS_forwardFD = Q.store_thm("liveFS_forwardFD[simp]",
  `liveFS (forwardFD fs fd n) = liveFS fs`,
  rw[liveFS_def]);

val MAP_FST_forwardFD_infds = Q.store_thm("MAP_FST_forwardFD_infds[simp]",
  `MAP FST (forwardFD fs fd n).infds = MAP FST fs.infds`,
  rw[forwardFD_def]);

val validFD_forwardFD = Q.store_thm("validFD_forwardFD[simp]",
  `validFD fd (forwardFD fs fd n)= validFD fd fs`,
  rw[validFD_def]);

val wfFS_forwardFD = Q.store_thm("wfFS_forwardFD[simp]",
  `wfFS (forwardFD fs fd n) = wfFS fs`,
  rw[wfFS_def]
  \\ rw[forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ rw[EQ_IMP_THM]
  \\ res_tac \\ fs[]
  \\ FULL_CASE_TAC \\ fs[]
  \\ FULL_CASE_TAC \\ fs[]
  \\ Cases_on`x` \\ fs[]);

val get_file_content_forwardFD = Q.store_thm("get_file_content_forwardFD[simp]",
  `!fs fd c pos n.
    get_file_content (forwardFD fs fd n) fd =
    OPTION_MAP (I ## (+) n) (get_file_content fs fd)`,
  rw[get_file_content_def,forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[] \\ rw[]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[]);

val bumpFD_forwardFD = Q.store_thm("bumpFD_forwardFD",
  `bumpFD fd fs n = forwardFD fs fd n with numchars := THE (LTL fs.numchars)`,
  rw[bumpFD_def,forwardFD_def]);

val STDIO_bumpFD = Q.store_thm("STDIO_bumpFD[simp]",
  `STDIO (bumpFD fd fs n) = STDIO (forwardFD fs fd n)`,
  rw[bumpFD_forwardFD,STDIO_numchars]);

val lemma = Q.prove(
  `IOStream (strlit "stdin") ≠ IOStream (strlit "stdout") ∧
   IOStream (strlit "stdin") ≠ IOStream (strlit "stderr") ∧
   IOStream (strlit "stdout") ≠ IOStream (strlit "stderr")`,rw[]);

val STD_streams_forwardFD = Q.store_thm("STD_streams_forwardFD",
  `fd ≠ 1 ∧ fd ≠ 2 ⇒
   (STD_streams (forwardFD fs fd n) = STD_streams fs)`,
  rw[STD_streams_def,forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ Cases_on`fd = 0`
  >- (
    EQ_TAC \\ rw[]
    \\ fsrw_tac[ETA_ss][option_case_eq,PULL_EXISTS,PAIR_MAP]
    >- (
      qexists_tac`inp-n` \\ rw[]
      >- (
        Cases_on`fd = 0` \\ fs[]
        >- (
          last_x_assum(qspecl_then[`fd`,`inp`]mp_tac)
          \\ rw[] \\ rw[] \\ Cases_on`v` \\ fs[] )
        \\ last_x_assum(qspecl_then[`fd`,`off`]mp_tac)
        \\ rw[] )
      \\ metis_tac[PAIR,SOME_11,FST,SND,lemma] )
    \\ qexists_tac`inp+n` \\ rw[]
    \\ metis_tac[PAIR,SOME_11,FST,SND,lemma,ADD_COMM] )
  \\ EQ_TAC \\ rw[]
  \\ fsrw_tac[ETA_ss][option_case_eq,PULL_EXISTS,PAIR_MAP]
  \\ qexists_tac`inp` \\ rw[]
  \\ metis_tac[PAIR,SOME_11,FST,SND,lemma]);

val STD_streams_bumpFD = Q.store_thm("STD_streams_bumpFD",
  `fd ≠ 1 ∧ fd ≠ 2 ⇒
   (STD_streams (bumpFD fd fs n) = STD_streams fs)`,
  rw[bumpFD_forwardFD,GSYM STD_streams_numchars,STD_streams_forwardFD]);

val lineForwardFD_def = Define`
  lineForwardFD fs fd =
    case get_file_content fs fd of
    | NONE => fs
    | SOME (content, pos) =>
      if pos < LENGTH content
      then let (l,r) = SPLITP ((=)#"\n") (DROP pos content) in
        forwardFD fs fd (LENGTH l + if NULL r then 0 else 1)
      else fs`;

val IS_SOME_get_file_content_lineForwardFD = Q.store_thm("IS_SOME_get_file_content_lineForwardFD[simp]",
  `IS_SOME (get_file_content (lineForwardFD fs fd) fd) =
   IS_SOME (get_file_content fs fd)`,
  rw[lineForwardFD_def]
  \\ CASE_TAC \\ simp[]
  \\ CASE_TAC \\ simp[]
  \\ CASE_TAC \\ simp[]
  \\ pairarg_tac \\ simp[]);

val fastForwardFD_lineForwardFD = Q.store_thm("fastForwardFD_lineForwardFD[simp]",
  `fastForwardFD (lineForwardFD fs fd) fd = fastForwardFD fs fd`,
  rw[fastForwardFD_def,lineForwardFD_def]
  \\ TOP_CASE_TAC \\ fs[libTheory.the_def]
  \\ TOP_CASE_TAC \\ fs[libTheory.the_def]
  \\ TOP_CASE_TAC \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[]
  \\ fs[forwardFD_def,ALIST_FUPDKEY_ALOOKUP,get_file_content_def]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[libTheory.the_def]
  \\ fs[IO_fs_component_equality,ALIST_FUPDKEY_o]
  \\ match_mp_tac ALIST_FUPDKEY_eq
  \\ simp[] \\ rveq
  \\ imp_res_tac SPLITP_JOIN
  \\ pop_assum(mp_tac o Q.AP_TERM`LENGTH`)
  \\ simp[SUB_RIGHT_EQ]
  \\ rw[MAX_DEF,NULL_EQ] \\ fs[]);

val fastForwardFD_0 = Q.store_thm("fastForwardFD_0",
  `(∀content pos. get_file_content fs fd = SOME (content,pos) ⇒ LENGTH content ≤ pos) ⇒
   fastForwardFD fs fd = fs`,
  rw[fastForwardFD_def,get_file_content_def]
  \\ Cases_on`ALOOKUP fs.infds fd` \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[libTheory.the_def]
  \\ fs[IO_fs_component_equality]
  \\ match_mp_tac ALIST_FUPDKEY_unchanged
  \\ rw[] \\ rw[PAIR_MAP_THM]
  \\ rw[MAX_DEF]);

val fastForwardFD_forwardFD = Q.store_thm("fastForwardFD_forwardFD",
  `get_file_content fs fd = SOME (content,pos) ∧ pos + n ≤ LENGTH content ⇒
   fastForwardFD (forwardFD fs fd n) fd = fastForwardFD fs fd`,
  rw[fastForwardFD_def,get_file_content_def,forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ rw[]
  \\ pairarg_tac \\ fs[]
  \\ pairarg_tac \\ fs[libTheory.the_def]
  \\ fs[IO_fs_component_equality,ALIST_FUPDKEY_o]
  \\ match_mp_tac ALIST_FUPDKEY_eq
  \\ simp[MAX_DEF]);

val fsupdate_comm = Q.store_thm("fsupdate_comm",
 `!fs fd1 fd2 k1 p1 c1 fnm1 pos1 k2 p2 c2 fnm2 pos2.
    ALOOKUP fs.infds fd1 = SOME(fnm1, pos1) /\
  ALOOKUP fs.infds fd2 = SOME(fnm2, pos2) /\
  fnm1 <> fnm2 /\ fd1 <> fd2 /\ ¬ LFINITE fs.numchars ==>
  fsupdate (fsupdate fs fd1 k1 p1 c1) fd2 k2 p2 c2 =
  fsupdate (fsupdate fs fd2 k2 p2 c2) fd1 k1 p1 c1`,
  fs[fsupdate_def] >> rw[] >> fs[ALIST_FUPDKEY_ALOOKUP] >>
  rpt CASE_TAC >> fs[ALIST_FUPDKEY_comm,THE_LDROP_comm]);

val ALOOKUP_validFD = Q.store_thm("ALOOKUP_validFD",
  `ALOOKUP fs.infds fd = SOME (fname, pos) ⇒ validFD fd fs`,
  rw[validFD_def] >> imp_res_tac ALOOKUP_MEM >>
  fs[MEM_MAP] >> instantiate);

val STD_streams_nextFD = Q.store_thm("STD_streams_nextFD",
  `STD_streams fs ⇒ 3 ≤ nextFD fs`,
  rw[STD_streams_def,nextFD_def,MEM_MAP,EXISTS_PROD]
  \\ numLib.LEAST_ELIM_TAC \\ rw[]
  >- (
    CCONTR_TAC \\ fs[]
    \\ `CARD (count (LENGTH fs.infds + 1)) ≤ CARD (set (MAP FST fs.infds))`
    by (
      match_mp_tac (MP_CANON CARD_SUBSET)
      \\ simp[SUBSET_DEF,MEM_MAP,EXISTS_PROD] )
    \\ `CARD (set (MAP FST fs.infds)) ≤ LENGTH fs.infds` by metis_tac[CARD_LIST_TO_SET,LENGTH_MAP]
    \\ fs[] )
  \\ Cases_on`n=0` >- metis_tac[ALOOKUP_MEM]
  \\ Cases_on`n=1` >- metis_tac[ALOOKUP_MEM]
  \\ Cases_on`n=2` >- metis_tac[ALOOKUP_MEM]
  \\ decide_tac);

(* needed?
val STD_OstreamFD_def = Define`
  STD_OstreamFD fs fd ⇔
    ∃nm pos. ALOOKUP fs.infds fd = SOME (IOStream nm,pos) ∧
            nm ∈ IMAGE strlit {"stdout";"stderr"}`;

val NOT_STD_OstreamFD_1_2 = Q.store_thm("NOT_STD_OstreamFD_1_2",
  `STD_streams fs ∧ ¬STD_OstreamFD fs fd ⇒ fd ≠ 1 ∧ fd ≠ 2`,
  rw[STD_streams_def,STD_OstreamFD_def]
  \\ strip_tac \\ fs[] \\ rfs[]);

val STD_OstreamFD_lineForwardFD = Q.store_thm("STD_OstreamFD_lineForwardFD[simp]",
  `STD_OstreamFD (lineForwardFD fs fd1) fd2 ⇔ STD_OstreamFD fs fd2 `,
  rw[STD_OstreamFD_def,lineForwardFD_def]
  \\ CASE_TAC \\ simp[]
  \\ CASE_TAC \\ simp[]
  \\ CASE_TAC \\ simp[]
  \\ pairarg_tac \\ fs[]
  \\ simp[forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ TOP_CASE_TAC \\ fs[]
  \\ Cases_on`x` \\ fs[]
  \\ IF_CASES_TAC \\ fs[]);

val STD_OstreamFD_fastForwardFD = Q.store_thm("STD_OstreamFD_fastForwardFD[simp]",
  `STD_OstreamFD (fastForwardFD fs fd1) fd2 ⇔ STD_OstreamFD fs fd2`,
  rw[STD_OstreamFD_def,fastForwardFD_def]
  \\ Cases_on`ALOOKUP fs.infds fd1` \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[libTheory.the_def]
  \\ fs[ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC \\ fs[]
  \\ CASE_TAC \\ fs[]);

val STD_OstreamFD_fsupdate = Q.store_thm("STD_OstreamFD_fsupdate[simp]",
  `STD_OstreamFD (fsupdate fs a y z w) fd ⇔ STD_OstreamFD fs fd`,
  rw[STD_OstreamFD_def,fsupdate_def,ALIST_FUPDKEY_ALOOKUP]
  \\ TOP_CASE_TAC \\ fs[]
  \\ Cases_on`x` \\ fs[] \\ rw[]);

val STD_OstreamFD_up_stdo = Q.store_thm("STD_OstreamFD_up_stdo[simp]",
  `STD_OstreamFD (up_stdo fd' fs x) fd ⇔ STD_OstreamFD fs fd`,
  rw[up_stdo_def]);

val STD_OstreamFD_add_stdo = Q.store_thm("STD_OstreamFD_add_stdo[simp]",
  `STD_OstreamFD (add_stdo fd' nm fs x) fd ⇔ STD_OstreamFD fs fd`,
  rw[add_stdo_def]);

val STD_OstreamFD_openFileFS_nextFD = Q.store_thm("STD_OstreamFD_openFileFS_nextFD",
  `inFS_fname fs (File f) ∧ nextFD fs ≤ 255 ⇒
   ¬STD_OstreamFD (openFileFS f fs off) (nextFD fs)`,
  rw[STD_OstreamFD_def,ALOOKUP_inFS_fname_openFileFS_nextFD]);
*)

(* -- *)

(* -- *)

val openIn_spec = Q.store_thm(
  "openIn_spec",
  `∀s sv fs.
     FILENAME s sv ∧
     CARD (FDOM (alist_to_fmap fs.infds)) < 256 ⇒
     app (p:'ffi ffi_proj) ^(fetch_v "IO.openIn" (basis_st())) [sv]
       (IOFS fs)
       (POST
          (\wv. &(WORD (n2w (nextFD fs) :word8) wv ∧
                  validFD (nextFD fs) (openFileFS s fs 0) ∧
                  inFS_fname fs (File s)) *
                IOFS (openFileFS s fs 0))
          (\e. &(BadFileName_exn e ∧ ~inFS_fname fs (File s)) * IOFS fs))`,
  xcf "IO.openIn" (basis_st()) >>
  fs[FILENAME_def, strlen_def, IOFS_def, IOFS_iobuff_def] >>
  xpull >> rename [`W8ARRAY _ fnm0`] >>
  qmatch_goalsub_abbrev_tac`catfs fs` >>
  fs[iobuff_loc_def] >> xlet_auto
  >- (xsimpl >> Cases_on`s` \\ fs[]) >>
  ntac 3 (xlet_auto >- xsimpl) >>
  xlet_auto >- ( xsimpl >> simp[LENGTH_explode] ) >>
  simp[LUPDATE_APPEND2,LENGTH_explode] >>
  qmatch_goalsub_abbrev_tac`W8ARRAY _ fnm` >>
  `fnm = insert_atI (MAP (n2w o ORD) (explode s) ++ [0w]) 0 fnm0` by (
    simp[Abbr`fnm`,insert_atI_def,LENGTH_explode,Once DROP_CONS_EL,LUPDATE_def,ADD1] ) \\
  qunabbrev_tac`fnm` \\ fs[] \\ pop_assum kall_tac \\
  qmatch_goalsub_abbrev_tac`W8ARRAY _ fnm` >>
  qmatch_goalsub_abbrev_tac`catfs fs' * _` >>
  Cases_on `inFS_fname fs (File s)`
  >- (xlet `POSTv u2.
            &(UNIT_TYPE () u2 /\ nextFD fs < 256 /\
              validFD (nextFD fs) (openFileFS s fs 0)) *
            W8ARRAY iobuff_loc (LUPDATE 0w 0 (LUPDATE (n2w (nextFD fs)) 1 fnm)) *
            catfs fs'`
    >- (simp[Abbr`catfs`,Abbr`fs'`] >>
        xffi >> simp[iobuff_loc_def] >>
        simp[fsFFITheory.fs_ffi_part_def,IOx_def] >>
        qmatch_goalsub_abbrev_tac`IO st f ns` >>
        CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
        map_every qexists_tac[`ns`,`f`,`encode (openFileFS s fs 0)`,`st`]
        >> xsimpl >>
        simp[Abbr`f`,Abbr`st`,Abbr`ns`, mk_ffi_next_def,
             ffi_open_in_def, decode_encode_FS, Abbr`fnm`,
             getNullTermStr_insert_atI, MEM_MAP, ORD_BOUND, ORD_eq_0,
             dimword_8, MAP_MAP_o, o_DEF, char_BIJ,
             implode_explode, LENGTH_explode] >>
        `∃content. ALOOKUP fs.files (File s) = SOME content`
          by (fs[inFS_fname_def, ALOOKUP_EXISTS_IFF, MEM_MAP, EXISTS_PROD] >>
              metis_tac[]) >>
        imp_res_tac nextFD_ltX >>
        csimp[openFileFS_def, openFile_def, validFD_def]) >>
    xlet_auto >- xsimpl >>
    xlet_auto
    >- (xsimpl >> csimp[HD_LUPDATE] >> simp[Abbr`fnm`, LENGTH_insert_atI, LENGTH_explode]) >>
    fs[iobuff_loc_def] >> xlet_auto
    >- (xsimpl >> imp_res_tac WORD_UNICITY_R)
    >> xif
    >-(xapp >> simp[iobuff_loc_def] >> xsimpl >>
    fs[EL_LUPDATE,Abbr`fnm`,LENGTH_insert_atI,LENGTH_explode,wfFS_openFile,Abbr`fs'`,
       liveFS_openFileFS]) >>
    xlet_auto >- (xcon >> xsimpl)
    >- (xraise >> xsimpl >>
        sg `0 < LENGTH (LUPDATE (n2w (nextFD fs)) 1 fnm)`
        >-(
	  fs[] >> fs[markerTheory.Abbrev_def] >> fs[] >>
	  `0 + LENGTH (MAP (n2w ∘ ORD) (explode s) ++ [0w]) <= LENGTH fnm0`
        by (fs[LENGTH_explode]) >>
	  fs[LENGTH_insert_atI]) >>
        IMP_RES_TAC HD_LUPDATE >> fs[])) >>
  xlet `POSTv u2.
            &UNIT_TYPE () u2 * catfs fs *
            W8ARRAY iobuff_loc (LUPDATE 255w 0 fnm)`
  >- (simp[Abbr`catfs`,Abbr`fs'`] >> xffi >> simp[iobuff_loc_def] >>
      simp[fsFFITheory.fs_ffi_part_def,IOx_def] >>
      qmatch_goalsub_abbrev_tac`IO st f ns` >>
      CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
      map_every qexists_tac[`ns`,`f`,`st`,`st`] >> xsimpl >>
      simp[Abbr`f`,Abbr`st`,Abbr`ns`, mk_ffi_next_def,
	   ffi_open_in_def, decode_encode_FS, Abbr`fnm`,
	   getNullTermStr_insert_atI, MEM_MAP, ORD_BOUND, ORD_eq_0,
	   dimword_8, MAP_MAP_o, o_DEF, char_BIJ,
	   implode_explode, LENGTH_explode] >>
      simp[not_inFS_fname_openFile]) >>
  xlet_auto >-(xsimpl) >> fs[iobuff_loc] >> xlet_auto
  >- (xsimpl >> csimp[HD_LUPDATE] >> simp[Abbr`fnm`, LENGTH_insert_atI, LENGTH_explode]) >>
  xlet_auto >-(xsimpl \\ imp_res_tac WORD_UNICITY_R) >> xif
  >-(xapp >> xsimpl >> irule FALSITY >>
     sg `0 < LENGTH fnm`
     >-(fs[markerTheory.Abbrev_def] >>
        `0 + LENGTH (MAP (n2w ∘ ORD) (explode s) ++ [0w]) <= LENGTH fnm0`
            by (fs[LENGTH_explode]) >>
        fs[LENGTH_insert_atI]) >>
     fs[HD_LUPDATE])>>
  xlet_auto >-(xcon >> xsimpl) >> xraise >> xsimpl >>
  simp[BadFileName_exn_def,Abbr`fnm`, LENGTH_insert_atI,LENGTH_explode]
  );

(* STDIO version *)
val openIn_STDIO_spec = Q.store_thm(
  "openIn_STDIO_spec",
  `∀s sv fs.
     FILENAME s sv ∧
     CARD (FDOM (alist_to_fmap fs.infds)) < 256 ⇒
     app (p:'ffi ffi_proj) ^(fetch_v "IO.openIn" (basis_st())) [sv]
       (STDIO fs)
       (POST
          (\wv. &(WORD (n2w (nextFD fs) :word8) wv ∧
                  validFD (nextFD fs) (openFileFS s fs 0) ∧
                  inFS_fname fs (File s)) *
                STDIO (openFileFS s fs 0))
          (\e. &(BadFileName_exn e ∧ ~inFS_fname fs (File s)) * STDIO fs))`,
 rw[STDIO_def] >> xpull >> xapp_spec openIn_spec >>
 map_every qexists_tac [`emp`,`s`,`fs with numchars := ll`] >>
 xsimpl >> rw[] >> qexists_tac`ll` >> fs[openFileFS_fupd_numchars] >> xsimpl >>
 rw[] >>
 fs[nextFD_numchars,nextFD_numchars,openFileFS_fupd_numchars,STD_streams_openFileFS] >>
 fs[GSYM validFD_numchars,GSYM openFileFS_fupd_numchars,inFS_fname_numchars])

(* openOut, openAppend here *)

val close_spec = Q.store_thm(
  "close_spec",
  `∀(fdw:word8) fdv fs.
     WORD fdw fdv ⇒
     app (p:'ffi ffi_proj) ^(fetch_v "IO.close" (basis_st())) [fdv]
       (IOFS fs)
       (POST (\u. &(UNIT_TYPE () u /\ validFD (w2n fdw) fs) *
                 IOFS (fs with infds updated_by A_DELKEY (w2n fdw)))
             (\e. &(InvalidFD_exn e /\ ¬ validFD (w2n fdw) fs) * IOFS fs))`,
  xcf "IO.close" (basis_st()) >> fs[IOFS_def, IOFS_iobuff_def] >> xpull >>
  rename [`W8ARRAY _ buf`] >> cases_on`buf` >> fs[] >>
  xlet_auto >- xsimpl >> fs[LUPDATE_def] >>
  xlet`POSTv uv. &(UNIT_TYPE () uv) *
        W8ARRAY iobuff_loc ((if validFD (w2n fdw) fs then 1w else 0w) ::t) *
        IOx fs_ffi_part (if validFD (w2n fdw) fs then (fs with infds updated_by A_DELKEY (w2n fdw))
                                      else fs)`
  >-(xffi >> simp[iobuff_loc_def,IOFS_def,fsFFITheory.fs_ffi_part_def,IOx_def] >>
     qmatch_goalsub_abbrev_tac`IO st f ns` >> xsimpl >>
     qmatch_goalsub_abbrev_tac`_ ==>>IO (_ fs') f ns` >>
     CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
     map_every qexists_tac[`ns`,`f`,`encode fs'`,`st`] >> xsimpl >>
     unabbrev_all_tac >> CASE_TAC >> rw[] >>
     fs[mk_ffi_next_def, ffi_close_def, decode_encode_FS,
        getNullTermStr_insert_atI, ORD_BOUND, ORD_eq_0,option_eq_some,
        dimword_8, MAP_MAP_o, o_DEF, char_BIJ,
        implode_explode, LENGTH_explode,closeFD_def,LUPDATE_def] >>
        imp_res_tac validFD_ALOOKUP >> cases_on`fs` >> fs[IO_fs_infds_fupd] >>
        fs[validFD_def] >> imp_res_tac ALOOKUP_NONE >>
        fs[liveFS_def,IO_fs_infds_fupd]) >>
  NTAC 3 (xlet_auto >- xsimpl) >>
  CASE_TAC >> xif >> instantiate
  >-(xcon >> fs[IOFS_def,liveFS_def] >> xsimpl) >>
  xlet_auto >-(xcon >> xsimpl) >>
  xraise >> fs[InvalidFD_exn_def,IOFS_def] >> xsimpl);

val close_STDIO_spec = Q.store_thm(
  "close_STDIO_spec",
  `∀fd fs fdv.
     WORD (n2w fd:word8) fdv /\ fd >= 3 /\ fd <= 255 ⇒
     app (p:'ffi ffi_proj) ^(fetch_v "IO.close" (basis_st())) [fdv]
       (STDIO fs)
       (POST (\u. &(UNIT_TYPE () u /\ validFD fd fs) *
                 STDIO (fs with infds updated_by A_DELKEY fd))
             (\e. &(InvalidFD_exn e /\ ¬ validFD fd fs) * STDIO fs))`,
  rw[STDIO_def] >> xpull >> xapp_spec close_spec >>
  map_every qexists_tac [`emp`,`fs with numchars := ll`,`n2w fd`] >>
  xsimpl >> rw[] >> qexists_tac`ll` >> fs[validFD_def] >> xsimpl >>
  fs[STD_streams_def,ALOOKUP_ADELKEY] \\
  Cases_on`fd = 0` \\ fs[] \\ metis_tac[]);

(* TODO: remove redundant validFD assumption *)
val writei_spec = Q.store_thm("writei_spec",
 `wfFS fs ⇒ validFD fd fs ⇒ 0 < n ⇒
  fd <= 255 ⇒ LENGTH rest = 255 ⇒ i + n <= 255 ⇒
  get_file_content fs fd = SOME(content, pos) ⇒
  WORD (n2w fd:word8) fdv ⇒ WORD (n2w n:word8) nv ⇒ WORD (n2w i:word8) iv ⇒
  bc = h1 :: h2 :: h3 :: rest ⇒
  app (p:'ffi ffi_proj) ^(fetch_v "IO.writei" (basis_st())) [fdv;nv;iv]
  (IOx fs_ffi_part fs * W8ARRAY iobuff_loc bc)
  (POST
    (\nwv. SEP_EXISTS nw. &(NUM nw nwv) * &(nw > 0) * &(nw <= n) *
           W8ARRAY iobuff_loc (0w :: n2w nw :: n2w i :: rest) *
           IOx fs_ffi_part
               (fsupdate fs fd (1 + Lnext_pos fs.numchars) (pos + nw)
                  (insert_atI (TAKE nw (MAP (CHR o w2n) (DROP i rest))) pos
                                    content)))
    (\e. &(InvalidFD_exn e) * W8ARRAY iobuff_loc (1w:: n2w n::rest) * &(F) *
         IOFS (fs with numchars:= THE(LDROP (1 + Lnext_pos fs.numchars) fs.numchars))))`,
  strip_tac >>
  `?ll. fs.numchars = ll` by simp[]  >> fs[] >>
  `ll ≠ [||]`  by (cases_on`ll` >> fs[wfFS_def,liveFS_def,live_numchars_def]) >>
  `always (eventually (λll. ∃k. LHD ll = SOME k ∧ k ≠ 0)) ll`
    by fs[wfFS_def,liveFS_def,live_numchars_def] >>
  UNDISCH_TAC ``fs.numchars = ll`` >> LAST_X_ASSUM MP_TAC >>
  LAST_ASSUM MP_TAC >>
  qid_spec_tac `bc`>> qid_spec_tac `h3` >>  qid_spec_tac `h2` >> qid_spec_tac `h1` >>
  qid_spec_tac `fs` >> NTAC 2 (FIRST_X_ASSUM MP_TAC) >> qid_spec_tac `ll` >>
  HO_MATCH_MP_TAC always_eventually_ind >>
  xcf "IO.writei" (basis_st())
(* next el is <> 0 *)
  >-(sg`Lnext_pos ll = 0`
     >-(fs[Lnext_pos_def,Once Lnext_def,liveFS_def,live_numchars_def,always_thm] >>
        cases_on`ll` >> fs[]) >>
     NTAC 3 (xlet_auto >-(simp[LUPDATE_def] >> xsimpl>> metis_tac[])) >>
     xlet`POSTv uv. &(UNIT_TYPE () uv) *
            W8ARRAY iobuff_loc (0w:: n2w (MIN n k) :: n2w i :: rest) *
            IOx fs_ffi_part (fsupdate fs fd 1 (MIN n k + pos)
                          (TAKE pos content ++
                           TAKE (MIN n k) (MAP (CHR o w2n) (DROP i rest)) ++
                           DROP (MIN n k + pos) content))`
     >-(qmatch_goalsub_abbrev_tac` _ * _ * IOx _ fs'` >> xffi >> xsimpl >>
        fs[iobuff_loc,IOFS_def,IOx_def,fs_ffi_part_def,
               mk_ffi_next_def] >>
        qmatch_goalsub_abbrev_tac`IO st f ns` >>
        CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
        map_every qexists_tac[`ns`,`f`,`encode fs'`,`st`] >> xsimpl >>
        fs[Abbr`f`,Abbr`st`,Abbr`ns`,mk_ffi_next_def,
           ffi_write_def,decode_encode_FS,MEM_MAP, ORD_BOUND,ORD_eq_0,wfFS_LDROP,
           dimword_8, MAP_MAP_o,o_DEF,char_BIJ,implode_explode,LENGTH_explode,
           HD_LUPDATE,LUPDATE_def,option_eq_some,validFD_def,write_def,
           get_file_content_def] >>
        pairarg_tac >> xsimpl >>
        `MEM fd (MAP FST fs.infds)` by (metis_tac[MEM_MAP]) >>
        rw[] >> TRY(metis_tac[wfFS_fsupdate,liveFS_fsupdate]) >>
        EVAL_TAC >>
        qmatch_goalsub_abbrev_tac`_ /\ _ = SOME(xx, _ yy)` >>
        qexists_tac`(xx,yy)` >> xsimpl >> fs[Abbr`xx`,Abbr`yy`] >>
        cases_on`fs.numchars` >> fs[Abbr`fs'`,fsupdate_def]) >>
     qmatch_goalsub_abbrev_tac` _ * IOx _ fs'` >>
     qmatch_goalsub_abbrev_tac`W8ARRAY _ (_::m:: n2w i :: rest)` >>
     fs[iobuff_loc_def] >>
     NTAC 3 (xlet_auto >- xsimpl) >> xif >> fs[FALSE_def] >> instantiate >>
     NTAC 3 (xlet_auto >- xsimpl) >>
     xif >> fs[FALSE_def] >> instantiate >> xvar >> xsimpl >>
     fs[IOFS_def,wfFS_fsupdate,liveFS_fsupdate] >>
     instantiate >> fs[Abbr`fs'`,MIN_DEF,insert_atI_def] >> xsimpl ) >>
 (* next element is 0 *)
  cases_on`ll` >- fs[liveFS_def,live_numchars_def] >>
  NTAC 3 (xlet_auto >- (xsimpl >> EVAL_TAC >> fs[LUPDATE_def])) >>
  xlet`POSTv uv. &(UNIT_TYPE () uv) * W8ARRAY iobuff_loc (0w:: 0w :: n2w i :: rest) *
        IOx fs_ffi_part (fsupdate fs fd 1 pos
                          (TAKE pos content ++
                           TAKE 0 (MAP (CHR o w2n) (DROP i rest)) ++
                           DROP pos content))`
  >-(qmatch_goalsub_abbrev_tac` _ * _ * IOx _ fs'` >> xffi >> xsimpl >>
     fs[iobuff_loc,IOFS_def,IOx_def,fs_ffi_part_def,
            mk_ffi_next_def] >>
     qmatch_goalsub_abbrev_tac`IO st f ns` >>
     CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
     map_every qexists_tac[`ns`,`f`,`encode fs'`,`st`] >> xsimpl >>
     fs[Abbr`f`,Abbr`st`,Abbr`ns`,mk_ffi_next_def,
        ffi_write_def,decode_encode_FS,MEM_MAP, ORD_BOUND,ORD_eq_0,wfFS_LDROP,
        dimword_8, MAP_MAP_o,o_DEF,char_BIJ,implode_explode,LENGTH_explode,
        HD_LUPDATE,LUPDATE_def,option_eq_some,validFD_def,write_def,
        get_file_content_def] >>
     pairarg_tac >> xsimpl >>
     `MEM fd (MAP FST fs.infds)` by (metis_tac[MEM_MAP]) >>
     rw[] >> TRY(metis_tac[wfFS_fsupdate,liveFS_fsupdate,Abbr`fs'`]) >>
     EVAL_TAC >>
     qexists_tac`(0w::0w::n2w i::rest,fs')` >> fs[Abbr`fs'`,fsupdate_def]) >>
  NTAC 3 (xlet_auto >- xsimpl) >>
  xif >> fs[FALSE_def] >> instantiate >>
  NTAC 3 (xlet_auto >- xsimpl) >>
  xif >> fs[TRUE_def] >> instantiate >>
  qmatch_goalsub_abbrev_tac` _ * IOx _ fs'` >>
  xapp >> xsimpl >>
  CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
  qexists_tac`fs'` >> xsimpl >>
  (* hypotheses for induction call *)
  sg`t = fs'.numchars` >-(
    fs[Abbr`fs'`,fsupdate_def,get_file_content_def] >>
    pairarg_tac \\ fs[LDROP_1]) >>
  sg`fs' = fs with numchars := t`
  >-(imp_res_tac validFD_ALOOKUP >> fs[wfFS_def,Abbr`fs'`,fsupdate_def] >>
     fs[IO_fs_component_equality] >> fs[wfFS_def,get_file_content_def] >>
     pairarg_tac >> fs[ALIST_FUPDKEY_unchanged,LDROP_1]) >>
  fs[Abbr`fs'`,get_file_content_def,liveFS_def,live_numchars_def,fsupdate_def,LDROP_1,
     wfFS_fsupdate,validFD_def,liveFS_fsupdate,IOFS_def] >>
  pairarg_tac >> fs[ALIST_FUPDKEY_unchanged] >>
  fs[wfFS_def,liveFS_def,live_numchars_def] >>
  imp_res_tac always_thm >>
  `Lnext_pos (0:::t) = SUC(Lnext_pos t)` by
    (fs[Lnext_pos_def,Once Lnext_def]) >>
  fs[ADD] >> xsimpl >> cases_on`t` >> fs[] >> rw[]
  >> instantiate >> xsimpl);

(* TODO: remove redundant validFD assumption *)
val write_spec = Q.store_thm("write_spec",
 `!n fs fd i pos h1 h2 h3 rest bc fdv nv iv content.
  validFD fd fs ⇒ wfFS fs ⇒
  fd <= 255 ⇒ LENGTH rest = 255 ⇒ i + n <= 255 ⇒
  get_file_content fs fd = SOME(content, pos) ⇒
  WORD (n2w fd:word8) fdv ⇒ NUM n nv ⇒ NUM i iv ⇒
  bc = h1 :: h2 :: h3 :: rest ⇒
  app (p:'ffi ffi_proj) ^(fetch_v "IO.write" (basis_st())) [fdv;nv;iv]
  (IOx fs_ffi_part fs * W8ARRAY iobuff_loc bc)
  (POSTv nwv. SEP_EXISTS k.
     IOFS(fsupdate fs fd k (pos + n)
                   (insert_atI (TAKE n (MAP (CHR o w2n) (DROP i rest))) pos
                                    content)))`,
  strip_tac >> `?N. n <= N` by (qexists_tac`n` >> fs[]) >>
  FIRST_X_ASSUM MP_TAC >> qid_spec_tac`n` >>
  Induct_on`N` >>
  xcf "IO.write" (basis_st())
  >>(xlet_auto >- xsimpl >> xif
	 >-(TRY instantiate >> xcon >>
		simp[IOFS_iobuff_def,IOFS_def] >> xsimpl >> qexists_tac`0` >>
	    fs[fsupdate_unchanged,insert_atI_def] >> xsimpl)) >>
  NTAC 2 (xlet_auto >- xsimpl) >>
  PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  (* TODO: xlet_auto fails *)
  `h1::h2::h3::rest = h1::h2::h3::rest` by fs[] >>
  xlet_auto_spec (SOME writei_spec) >> xsimpl
  >-(simp[iobuff_loc_def] >> xsimpl >> rw[] >> instantiate >> xsimpl) >>
  xlet_auto >- xsimpl >> reverse xif
  >-(xcon >> xsimpl >> fs[IOFS_def,IOFS_iobuff_def] >> xsimpl >>
	 qexists_tac`(Lnext_pos fs.numchars + 1)` >> `nw = n` by fs[] >> xsimpl >>
     fs[wfFS_fsupdate,validFD_def,always_DROP,ALIST_FUPDKEY_ALOOKUP,
        liveFS_fsupdate,get_file_content_def]) >>
  NTAC 2 (xlet_auto >- xsimpl) >>
  qmatch_goalsub_abbrev_tac`IOx _ fs'` >>
  `n - nw<= N` by fs[] >>
  FIRST_X_ASSUM (ASSUME_TAC o Q.SPECL[`n-nw`]) >> rfs[] >>
  FIRST_X_ASSUM(ASSUME_TAC o Q.SPECL[`fs'`, `fd`,`nw + i`,`pos+nw`]) >>
  FIRST_X_ASSUM xapp_spec >> xsimpl >>
  qexists_tac`insert_atI (TAKE nw (MAP (CHR ∘ w2n) (DROP i rest))) pos content` >>
  NTAC 3 (strip_tac >-(
		  fs[Abbr`fs'`,liveFS_def,live_numchars_def,LDROP_1, wfFS_fsupdate,validFD_def,
			 always_DROP,ALIST_FUPDKEY_ALOOKUP,get_file_content_def] >>
		  pairarg_tac >> fs[fsupdate_def,always_DROP,ALIST_FUPDKEY_ALOOKUP] >>
          imp_res_tac NOT_LFINITE_DROP >>
          FIRST_X_ASSUM (ASSUME_TAC o Q.SPEC`(Lnext_pos fs.numchars + 1)`) >>
          fs[] >> imp_res_tac NOT_LFINITE_DROP_LFINITE)) >>
  rw[] >> qexists_tac`Lnext_pos fs.numchars + 1 + x` >>
  fs[wfFS_def,fsupdate_o,Abbr`fs'`,insert_atI_insert_atI] >>
  qmatch_abbrev_tac`_ (_ _ _ _ _ (_ c1 _ _)) ==>> _ (_ _ _ _ _ (_ c2 _ _)) * _` >>
  `c1 = c2` suffices_by xsimpl >> fs[Abbr`c1`,Abbr`c2`] >>
  PURE_REWRITE_TAC[Once (Q.SPECL [`i`,`nw`] ADD_COMM)] >>
  fs[Once ADD_COMM,GSYM DROP_DROP_T,take_drop_partition,MAP_DROP]);

(* TODO: remove redundant validFD assumption *)
val write_char_spec = Q.store_thm("write_char_spec",
  `!fd fdv c cv bc content pos.
    validFD fd fs ⇒ fd <= 255 ⇒
    get_file_content fs fd = SOME(content, pos) ⇒
    CHAR c cv ⇒ WORD (n2w fd: word8) fdv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.write_char" (basis_st())) [fdv; cv]
    (IOFS fs)
    (POSTv uv.
      &UNIT_TYPE () uv * SEP_EXISTS k.
      IOFS (fsupdate fs fd k (pos+1) (insert_atI [c] pos content)))`,
  xcf "IO.write_char" (basis_st()) >> fs[IOFS_def,IOFS_iobuff_def] >>
  xpull >> rename [`W8ARRAY _ bdef`] >>
  ntac 3 (xlet_auto >- xsimpl) >>
  Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
  Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
  Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest'` >>
  Cases_on `rest'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1::h2::h3::h4::rest` >>
  simp[EVAL ``LUPDATE rr 2 (zz :: tt)``, EVAL ``LUPDATE rr 1 (zz :: tt)``,
       EVAL ``LUPDATE rr 3 (uu :: zz :: tt)``, LUPDATE_def] >>
  PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  xlet_auto
  >-(PURE_REWRITE_TAC[GSYM iobuff_loc_def] >> xsimpl >>
     rw[] >> qexists_tac`x` >> xsimpl) >>
     (* instantiate fails here *)
  xcon >> fs[IOFS_def,IOFS_iobuff_def] >> xsimpl >> rw[] >>
  fs[CHR_ORD,LESS_MOD,ORD_BOUND] >> qexists_tac`k` >> xsimpl);

val write_char_STDIO_spec = Q.store_thm("write_char_STDIO_spec",
  `fd <= 255 ∧ get_file_content fs fd = SOME(content, pos) ∧
   CHAR c cv ∧ WORD (n2w fd: word8) fdv ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.write_char" (basis_st())) [fdv; cv]
   (STDIO fs)
   (POSTv uv.
     &UNIT_TYPE () uv *
     STDIO (fsupdate fs fd 0 (pos+1) (insert_atI [c] pos content)))`,
  rw[STDIO_def] \\ xpull \\ xapp_spec write_char_spec \\
  mp_tac(SYM(SPEC_ALL get_file_content_numchars)) \\ rw[] \\
  instantiate \\ simp[GSYM validFD_numchars] \\ xsimpl \\
  conj_tac >- imp_res_tac get_file_content_validFD \\ rw[] \\
  qexists_tac`THE (LDROP x ll)` \\
  conj_tac >- (
    match_mp_tac STD_streams_fsupdate \\ fs[] \\
    fs[STD_streams_def,get_file_content_def] \\
    pairarg_tac \\ fs[] \\
    first_x_assum(qspecl_then[`2`,`LENGTH err`]mp_tac) \\
    first_x_assum(qspecl_then[`1`,`LENGTH out`]mp_tac) \\
    rw[] \\ rfs[] \\ rw[] \\ fs[] \\
    simp[insert_atI_def,LENGTH_TAKE_EQ] )
  \\ qmatch_abbrev_tac`IOFS fs1 ==>> IOFS fs2 * _`
  \\ `fs1 = fs2` suffices_by xsimpl
  \\ fs[get_file_content_def] \\ pairarg_tac \\ fs[]
  \\ rw[Abbr`fs1`,Abbr`fs2`,IO_fs_component_equality,fsupdate_def]);

(* TODO: remove redundant validFD assumption *)
val output_spec = Q.store_thm("output_spec",
  `!s fd fdv sv fs content pos.
    WORD (n2w fd :word8) fdv ⇒ validFD fd fs ⇒ STRING_TYPE s sv ⇒ fd <= 255 ⇒
    (get_file_content fs fd = SOME(content, pos)) ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.output" (basis_st())) [fdv; sv]
    (IOFS fs)
    (POSTv uv. &(UNIT_TYPE () uv) *
       SEP_EXISTS k. IOFS (fsupdate fs fd k (pos + (strlen s))
                                    (insert_atI (explode s) pos content)))`,
  strip_tac >>
  `?n. strlen s <= n` by (qexists_tac`strlen s` >> fs[]) >>
  FIRST_X_ASSUM MP_TAC >> qid_spec_tac`s` >>
  Induct_on`n` >>
  xcf "IO.output" (basis_st()) >> fs[IOFS_def,IOFS_iobuff_def] >>
  xpull >> rename [`W8ARRAY _ buff`] >>
  Cases_on `buff` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
  Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: rest'` >>
  Cases_on `rest'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1::h2::h3::rest` >>
  (xlet_auto >- xsimpl) >>
  (xif >-(xcon >> xsimpl >> qexists_tac`0` >>
         fs[fsupdate_unchanged,insert_atI_NIL] >> xsimpl))
  >-(cases_on`s` >> fs[strlen_def]) >>
  fs[insert_atI_def] >>
  xlet_auto >- xsimpl >>
  xlet_auto >- xsimpl >>
  xlet`POSTv mv. &NUM (MIN (strlen s) 255) mv * IOx fs_ffi_part fs * W8ARRAY (Loc 1) (h1::h2::h3::rest)`
  >- (
    xif
    >- (xret \\ xsimpl \\ fs[NUM_def,INT_def,MIN_DEF] )
    \\ xlit \\ xsimpl \\ fs[MIN_DEF] ) >>
  xlet_auto >- xsimpl >>
  fs[insert_atI_def] >> PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  xlet_auto >> xsimpl
  >-(PURE_REWRITE_TAC[GSYM iobuff_loc_def] >> xsimpl >>
     fs[LENGTH_explode,strlen_substring]) >>
  sg`OPTION_TYPE NUM NONE (Conv (SOME ("NONE",TypeId (Short "option"))) [])`
  >- fs[OPTION_TYPE_def] >>
  xlet_auto >- xsimpl >>
  xlet_auto >- xsimpl >>
  qmatch_goalsub_abbrev_tac`fsupdate fs _ _ pos' content'` >>
  qmatch_goalsub_abbrev_tac`IOFS fs'` >>
  fs[IOFS_def] >> xpull >>
  xapp >> fs[IOFS_iobuff_def,IOFS_def] >> xsimpl >>
  CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
  map_every qexists_tac [`content'`,`fd`,`fs'`,`pos'`] >>
  instantiate >> xsimpl >>
  `strlen s <> 0` by (cases_on`s` >> cases_on`s'` >> fs[])>>
  fs[strlen_substring] >>
  fs[get_file_content_def] >> pairarg_tac >>
  fs[Abbr`fs'`,Abbr`pos'`,Abbr`content'`,liveFS_def,live_numchars_def,
     fsupdate_def,LDROP_1, wfFS_fsupdate,validFD_def,always_DROP,
     ALIST_FUPDKEY_ALOOKUP,extract_def,strlen_extract_le,
     MIN_DEF] >> xsimpl >>
  rpt strip_tac >>
  qexists_tac`x' + k` >> fs[insert_atI_def] >>
  qmatch_goalsub_abbrev_tac`IOx _ fs1 ==>> IOx _ fs2 * GC` >>
  `fs1 = fs2` suffices_by xsimpl >> fs[Abbr`fs1`,Abbr`fs2`] >>
  reverse conj_tac >- (
    reverse conj_tac >- (
      fs[LDROP_ADD] \\
      CASE_TAC \\ fs[] \\
      imp_res_tac LDROP_NONE_LFINITE
      \\ fs[wfFS_def,liveFS_def,live_numchars_def] ) >>
    fs[ALIST_FUPDKEY_o] >>
    match_mp_tac ALIST_FUPDKEY_eq >>
    fs[PAIR_MAP_THM,FORALL_PROD] ) >>
  fs[ALIST_FUPDKEY_o] >>
  match_mp_tac ALIST_FUPDKEY_eq >>
  simp[] >>
  fs[MAP_MAP_o,CHR_w2n_n2w_ORD] >>
  IF_CASES_TAC >-
    fs[substring_too_long,TAKE_APPEND,TAKE_TAKE,TAKE_LENGTH_TOO_LONG,
       LENGTH_explode,DROP_APPEND,LENGTH_TAKE_EQ,DROP_LENGTH_TOO_LONG] >>
  fs[LENGTH_explode,strlen_substring] >>
  fs[TAKE_APPEND,DROP_APPEND,LENGTH_TAKE_EQ,LENGTH_explode,
     strlen_substring,DROP_LENGTH_TOO_LONG,TAKE_LENGTH_ID_rwt] >>
  IF_CASES_TAC \\
  fs[TAKE_LENGTH_ID_rwt,LENGTH_explode,strlen_substring,
     DROP_DROP_T,TAKE_LENGTH_TOO_LONG,DROP_LENGTH_TOO_LONG]
  \\ Cases_on`s` \\ fs[substring_def,SEG_TAKE_BUTFISTN,TAKE_LENGTH_ID_rwt]);

val read_spec = Q.store_thm("read_spec",
  `!fs fd fdv n nv. fd <= 255 ⇒ wfFS fs ⇒
   WORD (n2w fd:word8) fdv ⇒ WORD (n:word8) nv ⇒
   LENGTH rest = 255 ⇒  w2n n <= 255 ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.read" (basis_st())) [fdv;nv]
   (W8ARRAY iobuff_loc (h1 :: h2 :: h3 :: rest) * IOx fs_ffi_part fs)
   (POST
     (\nrv. SEP_EXISTS (nr : num).
      &(NUM nr nrv) *
      SEP_EXISTS content pos.
        &(get_file_content fs fd = SOME(content, pos) /\
          (nr <= MIN (w2n n) (LENGTH content - pos)) /\
          (nr = 0 ⇔ eof fd fs = SOME T ∨ w2n n = 0)) *
      IOx fs_ffi_part (bumpFD fd fs nr) *
      W8ARRAY iobuff_loc (0w :: n2w nr :: h3 ::
        MAP (n2w o ORD) (TAKE nr (DROP pos content))++DROP nr rest))
     (\e. &InvalidFD_exn e * &(get_file_content fs fd = NONE) * IOFS fs))`,
   xcf "IO.read" (basis_st()) >> fs[IOFS_def,IOFS_iobuff_def] >>
   NTAC 2 (xlet_auto >- (fs[LUPDATE_def] >> xsimpl)) >>
   simp[LUPDATE_def,EVAL ``LUPDATE rr 1 (zz :: tt)``] >>
   cases_on`get_file_content fs fd`
   >-(xlet`POSTv v. W8ARRAY (Loc 1) (1w::n::h3::rest) * IOx fs_ffi_part fs`
      >-(xffi >> xsimpl >>
         fs[iobuff_loc,IOFS_def,IOx_def,fs_ffi_part_def, mk_ffi_next_def] >>
         qmatch_goalsub_abbrev_tac`IO st f ns` >>
         CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
         map_every qexists_tac[`ns`,`f`] >>
         xsimpl >>
         fs[Abbr`f`,Abbr`st`,Abbr`ns`,mk_ffi_next_def, ffi_read_def,
            decode_encode_FS,MEM_MAP, ORD_BOUND,ORD_eq_0,wfFS_LDROP,
            dimword_8, MAP_MAP_o,o_DEF,char_BIJ,implode_explode,LENGTH_explode,
            HD_LUPDATE,LUPDATE_def,option_eq_some,validFD_def,read_def,
            get_file_content_def,n2w_w2n,w2n_n2w] >> rfs[] >>
         pairarg_tac >> fs[]) >>
      rpt(xlet_auto >- xsimpl) >> xif >> instantiate >>
      xlet_auto >-(xcon >> xsimpl >> instantiate >> xsimpl) >>
      xraise >> xsimpl >> fs[InvalidFD_exn_def] >> xsimpl) >>
   cases_on`x` >> fs[] >>
   xlet `POST (\uv. SEP_EXISTS nr nrv . &(NUM nr nrv) *
      SEP_EXISTS content pos.  &(get_file_content fs fd = SOME(content, pos) /\
          (nr <= MIN (w2n n) (LENGTH content - pos)) /\
          (nr = 0 ⇔ eof fd fs = SOME T ∨ w2n n = 0)) *
        IOx fs_ffi_part (bumpFD fd fs nr) *
        W8ARRAY iobuff_loc (0w :: n2w nr :: h3 ::
          MAP (n2w o ORD) (TAKE nr (DROP pos content))++DROP nr rest))
            (\e. &(get_file_content fs fd = NONE))` >> xsimpl
   >-(xffi >> xsimpl >>
      fs[iobuff_loc,IOFS_def,IOx_def,fs_ffi_part_def, mk_ffi_next_def] >>
      qmatch_goalsub_abbrev_tac`IO st f ns` >>
      CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
      map_every qexists_tac[`ns`,`f`] >>
      xsimpl >>
      fs[Abbr`f`,Abbr`st`,Abbr`ns`,mk_ffi_next_def,
         ffi_read_def,decode_encode_FS,MEM_MAP, ORD_BOUND,ORD_eq_0,wfFS_LDROP,
         dimword_8, MAP_MAP_o,o_DEF,char_BIJ,implode_explode,LENGTH_explode,
         HD_LUPDATE,LUPDATE_def,option_eq_some,validFD_def,read_def,
         get_file_content_def] >> rfs[] >>
      pairarg_tac >> xsimpl >> fs[] >>
      cases_on`fs.numchars` >> fs[wfFS_def,liveFS_def,live_numchars_def] >>
      qmatch_goalsub_abbrev_tac`k = _ MOD 256` >> qexists_tac`k` >>
      xsimpl >> fs[MIN_LE,eof_def,Abbr`k`,NUM_def,INT_def] >>
      rfs[liveFS_bumpFD] >> metis_tac[]) >>
   rpt(xlet_auto >- xsimpl) >>
   xif >> instantiate >> xlet_auto >- xsimpl >>
   xapp >> xsimpl >> instantiate >>
   rw[] >> instantiate >> xsimpl);

val read_byte_spec = Q.store_thm("read_byte_spec",
  `!fd fdv content pos.
    WORD (n2w fd : word8) fdv ⇒ fd <= 255 ⇒
    get_file_content fs fd = SOME(content, pos) ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.read_byte" (basis_st())) [fdv]
    (IOFS fs)
    (POST (\cv. &(WORD (n2w (ORD (EL pos content)):word8) cv /\
                eof fd fs = SOME F) *
                IOFS (bumpFD fd fs 1))
          (\e.  &(EndOfFile_exn e /\ eof fd fs = SOME T) *
                IOFS(bumpFD fd fs 0)))`,
  xcf "IO.read_byte" (basis_st()) >> fs[IOFS_def,IOFS_iobuff_def] >>
  xpull >> rename [`W8ARRAY _ bdef`] >>
  Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
  Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
  Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest` >>
  xlet_auto >- xsimpl >>
  PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  xlet_auto >-(fs[iobuff_loc_def] >> xsimpl >> rw[] >> instantiate >> xsimpl)
  >- xsimpl >>
  xlet_auto >- xsimpl >>
  xif >-(xlet_auto >- (xcon >> xsimpl) >> xraise >>
         fs[EndOfFile_exn_def,eof_def,get_file_content_def,liveFS_bumpFD] >> xsimpl) >>
  xapp >> xsimpl >>
  `nr = 1` by fs[] >> fs[] >> xsimpl >>
  fs[take1_drop,eof_def,get_file_content_def] >> pairarg_tac >> fs[liveFS_bumpFD]);

val read_byte_STDIO_spec = Q.store_thm("read_byte_STDIO_spec",
  ` WORD (n2w fd : word8) fdv ∧ fd <= 255 ∧ fd ≠ 1 ∧ fd ≠ 2 ∧
    get_file_content fs fd = SOME(content, pos) ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.read_byte" (basis_st())) [fdv]
    (STDIO fs)
    (POST (\cv. &(WORD (n2w (ORD (EL pos content)):word8) cv /\
                eof fd fs = SOME F) *
                STDIO (bumpFD fd fs 1))
          (\e.  &(EndOfFile_exn e /\ eof fd fs = SOME T) *
                STDIO(bumpFD fd fs 0)))`,
  rw[STDIO_def] >> xpull >> xapp_spec read_byte_spec >>
  mp_tac(GSYM(SPEC_ALL get_file_content_numchars)) >> rw[] >>
  instantiate >> xsimpl >>
  simp[bumpFD_forwardFD,forwardFD_numchars,STD_streams_forwardFD] \\
  rw[] \\ qexists_tac`THE (LTL ll)` \\ xsimpl);

(* TODO: call the low-level IOFS specs with the non-standard name, not vice versa *)

val read_char_spec = Q.store_thm("read_char_spec",
  ` WORD (n2w fd : word8) fdv ∧ fd <= 255 ∧ fd ≠ 1 ∧ fd ≠ 2 ∧
    get_file_content fs fd = SOME(content, pos) ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.read_char" (basis_st())) [fdv]
    (STDIO fs)
    (POST (\cv. &(CHAR (EL pos content) cv /\
                eof fd fs = SOME F) *
                STDIO (bumpFD fd fs 1))
          (\e.  &(EndOfFile_exn e /\ eof fd fs = SOME T) *
                STDIO(bumpFD fd fs 0)))`,
  xcf"IO.read_char"(get_ml_prog_state())
  \\ xlet_auto_spec(SOME read_byte_STDIO_spec)
  \\ xsimpl \\ simp[bumpFD_0] \\ xsimpl
  \\ xlet_auto \\ xsimpl
  \\ xapp \\ xsimpl
  \\ instantiate
  \\ fs[ORD_BOUND,CHR_ORD]);

val input_spec = Q.store_thm("input_spec",
  `!fd fdv fs content pos off offv.
    len + off <= LENGTH buf ⇒ pos <= LENGTH content  ⇒
    WORD (n2w fd : word8) fdv ⇒ NUM off offv ⇒ NUM len lenv ⇒
    fd <= 255 ⇒ (get_file_content fs fd = SOME(content, pos)) ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.input" (basis_st())) [fdv; bufv; offv; lenv]
    (IOFS fs * W8ARRAY bufv buf)
    (POSTv nv. &(NUM (MIN len (LENGTH content - pos)) nv) *
       W8ARRAY bufv (insert_atI (TAKE len (DROP pos (MAP (n2w o ORD) content)))
                                 off buf) *
       SEP_EXISTS k. IOFS (fsupdate fs fd k (MIN (len + pos) (LENGTH content)) content))`,
 xcf "IO.input" (basis_st()) >>
 xfun_spec`input0`
  `!count countv buf fs pos off offv lenv.
    len + off <= LENGTH buf ⇒ pos <= LENGTH content  ⇒ NUM count countv ⇒
    WORD (n2w fd : word8) fdv ⇒ NUM off offv ⇒ NUM len lenv ⇒
    fd <= 255 ⇒ (get_file_content fs fd = SOME(content, pos)) ⇒
    app (p:'ffi ffi_proj) input0
        [offv; lenv; countv]
    (IOFS fs * W8ARRAY bufv buf)
    (POSTv nv. &(NUM (count + MIN len (LENGTH content - pos)) nv) *
       W8ARRAY bufv (insert_atI (TAKE len (DROP pos (MAP (n2w o ORD) content)))
                                 off buf) *
       SEP_EXISTS k. IOFS (fsupdate fs fd k (MIN (len + pos) (LENGTH content)) content))` >-
 (`?N. len <= N` by (qexists_tac`len` >> fs[]) >>
  FIRST_X_ASSUM MP_TAC >> qid_spec_tac`len` >>
  Induct_on`N` >> rw[]
  >-(xapp >> fs[IOFS_def,IOFS_iobuff_def] >> xpull >>
     NTAC 2 (xlet_auto >- xsimpl) >>
     rename [`W8ARRAY (Loc 1) bdef`] >>
     Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
     Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
     Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest` >>
     PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
     xlet_auto >-(fs[iobuff_loc_def] >> xsimpl) >- xsimpl >>
     xlet_auto >-xsimpl >>
     xif >> instantiate >> xlit >> xsimpl >>
     qexists_tac `1` >>
     fs[get_file_content_def] >> pairarg_tac >> rw[] >>
     fs[wfFS_fsupdate,liveFS_fsupdate,MIN_DEF,MEM_MAP,insert_atI_NIL,
        validFD_ALOOKUP, bumpFD_def, fsupdate_def,LDROP_1,
        ALIST_FUPDKEY_unchanged,wfFS_def,liveFS_def,live_numchars_def] >>
     cases_on`fs'.numchars` >> fs[LDROP_1,NOT_LFINITE_DROP_LFINITE] >>
     cases_on`fs'.numchars` >> fs[LDROP_1] >> cases_on`fs` >>
     qmatch_abbrev_tac`IOx _ fs1 ==>> IOx _ fs2 * GC` >>
     `fs1 = fs2` by (unabbrev_all_tac >>
                     fs[IO_fs_component_equality,ALIST_FUPDKEY_unchanged]) >>
     xsimpl) >>
  last_x_assum xapp_spec>> fs[IOFS_def,IOFS_iobuff_def] >> xpull >>
  rw[] >> cases_on`len'`
  >-(rw[] >>
     NTAC 2 (xlet_auto >- xsimpl) >>
     rename [`W8ARRAY (Loc 1) bdef`] >>
     Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
     Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
     Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest` >>
     PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
     xlet_auto >-(fs[iobuff_loc_def] >> xsimpl) >- xsimpl >>
     xlet_auto >- xsimpl >> xif >> instantiate >> xlit >> xsimpl >>
     qexists_tac `1` >>
     fs[get_file_content_def] >> pairarg_tac >> rw[] >>
     fs[wfFS_fsupdate,liveFS_fsupdate,MIN_DEF,MEM_MAP,insert_atI_NIL,
        validFD_ALOOKUP, bumpFD_def, fsupdate_def,LDROP_1,
        ALIST_FUPDKEY_unchanged,wfFS_def,liveFS_def,live_numchars_def] >>
     cases_on`fs'.numchars` >> fs[LDROP_1,NOT_LFINITE_DROP_LFINITE] >>
     cases_on`fs'.numchars` >> fs[LDROP_1] >> cases_on`fs` >>
     qmatch_abbrev_tac`IOx _ fs1 ==>> IOx _ fs2 * GC` >>
     `fs1 = fs2` suffices_by xsimpl >>
     unabbrev_all_tac >> fs[IO_fs_component_equality,ALIST_FUPDKEY_unchanged]) >>
  NTAC 2 (xlet_auto >- xsimpl) >>
  rename [`W8ARRAY (Loc 1) bdef`] >>
  Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
  Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
  Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest` >>
  PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  xlet_auto
  >-(fs[iobuff_loc_def] >> xsimpl >> rw[] >> TRY instantiate >> xsimpl)
  >- xsimpl >>
  xlet_auto >- xsimpl >>
  `MEM fd (MAP FST fs'.infds)` by
     (fs[get_file_content_def] >> pairarg_tac >> fs[ALOOKUP_MEM,MEM_MAP] >>
      qexists_tac`fd,(fnm, pos'')` >> fs[ALOOKUP_MEM]) >>
  xif
  >-(xvar >> xsimpl >> qexists_tac`1` >>
     fs[eof_def] >> pairarg_tac >> fs[get_file_content_def] >>
     pairarg_tac \\ fs[] \\ rveq \\
     `LENGTH content = pos'` by (fs[] >> rfs[]) >>
     fs[MIN_DEF,liveFS_fsupdate,insert_atI_NIL,bumpFD_def,ALIST_FUPDKEY_unchanged] >>
     rw[DROP_NIL] >- fs[validFD_def,wfFS_fsupdate]
     >- fs[GSYM MAP_DROP,DROP_LENGTH_NIL,insert_atI_NIL] >>
     qmatch_abbrev_tac `IOx _ fs1 ==>> IOx _ fs2 * GC` >>
     `fs1 = fs2` suffices_by xsimpl >>
     unabbrev_all_tac >> cases_on`fs'.numchars` >>
     fs[IO_fs_component_equality,ALIST_FUPDKEY_unchanged,fsupdate_def,LDROP_1,
        wfFS_def,liveFS_def,live_numchars_def]) >>
  NTAC 4 (xlet_auto >- xsimpl) >>
  PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
  qmatch_goalsub_abbrev_tac`W8ARRAY bufv buf'' * W8ARRAY iobuff_loc _ *
                            IOx fs_ffi_part fs''` >>
  xapp >> xsimpl >>
  CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
  map_every qexists_tac[`count' + nr`, `fs''`, `SUC n - nr`, `off' + nr`, `pos' + nr`] >>
  unabbrev_all_tac >>
  fs[get_file_content_def, validFD_bumpFD,liveFS_bumpFD,bumpFD_def] >>
  xsimpl >>
  fs[get_file_content_def, validFD_bumpFD,liveFS_bumpFD,bumpFD_def,
     ALIST_FUPDKEY_ALOOKUP,INT_OF_NUM_SUBS_2,NUM_def,INT_def] >>
  rw[] >> qexists_tac`SUC x''` >>
  fs[NUM_def,INT_def,MIN_DEF,validFD_def,wfFS_fsupdate,liveFS_fsupdate] >>
  strip_tac
  >-(fs[insert_atI_def,TAKE_APPEND,GSYM MAP_TAKE,TAKE_TAKE_MIN,MIN_DEF] >>
     fs[MAP_TAKE,MAP_DROP,GSYM DROP_DROP] >>
     fs[take_drop_partition,LENGTH_TAKE,LENGTH_DROP,LENGTH_MAP,DROP_APPEND] >>
     qmatch_goalsub_abbrev_tac `l1 ++ l2 ++ l3 = l4` >>
     `l1 = []` by (unabbrev_all_tac >> fs[DROP_NIL,LENGTH_TAKE]) >>
     `l2 = []` by (unabbrev_all_tac >> fs[DROP_NIL,LENGTH_TAKE]) >>
     fs[] >> unabbrev_all_tac >>
     fs[LENGTH_TAKE_EQ_MIN,DROP_DROP_T,MIN_DEF] >> CASE_TAC >> fs[]) >>
  qmatch_abbrev_tac `IOx _ fs1 ==>> IOx _ fs2 * GC` >>
  `fs1 = fs2` suffices_by xsimpl >>
  unabbrev_all_tac >> cases_on`fs'.numchars` >> fs[wfFS_def,liveFS_def,live_numchars_def] >>
  pairarg_tac \\
  fs[IO_fs_component_equality,ALIST_FUPDKEY_unchanged,fsupdate_def,LDROP_1] >>
  fs[ALIST_FUPDKEY_ALOOKUP,ALIST_FUPDKEY_o,ALIST_FUPDKEY_eq] >>
  simp[ALIST_FUPDKEY_unchanged])
  \\ xapp \\ instantiate \\ xsimpl);

(* convenient functions for standard output/error
* to be used with STDIO as numchars is ignored *)

val stdo_def = Define`
  stdo fd name fs out =
    (ALOOKUP fs.infds fd = SOME(IOStream(strlit name),LENGTH out) /\
     ALOOKUP fs.files (IOStream(strlit name)) = SOME out)`;

val _ = overload_on("stdout",``stdo 1 "stdout"``);
val _ = overload_on("stderr",``stdo 2 "stderr"``);

val stdo_UNICITY_R = Q.store_thm("stdo_UNICITY_R[xlet_auto_match]",
`!fd name fs out out'. stdo fd name fs out ==> (stdo fd name fs out' <=> out = out')`,
rw[stdo_def] >> EQ_TAC >> rw[]);

val up_stdo_def = Define
`up_stdo fd fs out = fsupdate fs fd 0 (LENGTH out) out`
val _ = overload_on("up_stdout",``up_stdo 1``);
val _ = overload_on("up_stderr",``up_stdo 2``);

val stdin_def = Define
`stdin fs inp pos = (ALOOKUP fs.infds 0 = SOME(IOStream(strlit"stdin"),pos) /\
                     ALOOKUP fs.files (IOStream(strlit"stdin"))= SOME inp)`

val up_stdin_def = Define
`up_stdin inp pos fs = fsupdate fs 0 0 pos inp`

val stdo_numchars = Q.store_thm("stdo_numchars",
  `stdo fd name (fs with numchars := l) out ⇔ stdo fd name fs out`,
  rw[stdo_def]);

val add_stdo_def = Define`
  add_stdo fd nm fs out = up_stdo fd fs ((@init. stdo fd nm fs init) ++ out)`;
val _ = overload_on("add_stdout",``add_stdo 1 "stdout"``);
val _ = overload_on("add_stderr",``add_stdo 2 "stderr"``);

val stdo_add_stdo = Q.store_thm("stdo_add_stdo",
  `stdo fd nm fs init ⇒ stdo fd nm (add_stdo fd nm fs out) (init++out)`,
  rw[add_stdo_def]
  \\ SELECT_ELIM_TAC \\ rw[] >- metis_tac[]
  \\ imp_res_tac stdo_UNICITY_R \\ rveq
  \\ fs[up_stdo_def,stdo_def,fsupdate_def,ALIST_FUPDKEY_ALOOKUP]);

val up_stdo_unchanged = Q.store_thm("up_stdo_unchanged",
 `!fs out. stdo fd nm fs out ==> up_stdo fd fs out = fs`,
fs[up_stdo_def,stdo_def,fsupdate_unchanged,get_file_content_def]);

val stdo_up_stdo = Q.store_thm("stdo_up_stdo",
 `!fs out out'. stdo fd nm fs out ==> stdo fd nm (up_stdo fd fs out') out'`,
 rw[up_stdo_def,stdo_def,fsupdate_def,ALIST_FUPDKEY_ALOOKUP]
 \\ rw[]);

val add_stdo_nil = Q.store_thm("add_stdo_nil",
  `stdo fd nm fs out ⇒ add_stdo fd nm fs "" = fs`,
  rw[add_stdo_def]
  \\ SELECT_ELIM_TAC
  \\ metis_tac[up_stdo_unchanged]);

val add_stdo_o = Q.store_thm("add_stdo_o",
  `stdo fd nm fs out ⇒
   add_stdo fd nm (add_stdo fd nm fs x1) x2 = add_stdo fd nm fs (x1 ++ x2)`,
  rw[add_stdo_def]
  \\ SELECT_ELIM_TAC \\ rw[] >- metis_tac[]
  \\ SELECT_ELIM_TAC \\ rw[] >- metis_tac[stdo_up_stdo]
  \\ imp_res_tac stdo_UNICITY_R \\ rveq
  \\ rename1`stdo _ _ (up_stdo _ _ _) l`
  \\ `l = out ++ x1` by metis_tac[stdo_UNICITY_R,stdo_up_stdo]
  \\ rveq \\ fs[up_stdo_def]);

val fsupdate_MAP_FST_infds = Q.store_thm("fsupdate_MAP_FST_infds[simp]",
  `MAP FST (fsupdate fs fd k pos c).infds = MAP FST fs.infds`,
  rw[fsupdate_def] \\ every_case_tac \\ rw[]);

val up_stdo_MAP_FST_infds = Q.store_thm("up_stdo_MAP_FST_infds[simp]",
  `MAP FST (up_stdo fd fs out).infds = MAP FST fs.infds`,
  rw[up_stdo_def]);

val add_stdo_MAP_FST_infds = Q.store_thm("add_stdo_MAP_FST_infds[simp]",
  `MAP FST (add_stdo fd nm fs out).infds = MAP FST fs.infds`,
  rw[add_stdo_def]);

val fsupdate_MAP_FST_files = Q.store_thm("fsupdate_MAP_FST_files[simp]",
  `MAP FST (fsupdate fs fd k pos c).files = MAP FST fs.files`,
  rw[fsupdate_def] \\ every_case_tac \\ rw[]);

val up_stdo_MAP_FST_files = Q.store_thm("up_stdo_MAP_FST_files[simp]",
  `MAP FST (up_stdo fd fs out).files = MAP FST fs.files`,
  rw[up_stdo_def]);

val add_stdo_MAP_FST_files = Q.store_thm("add_stdo_MAP_FST_files[simp]",
  `MAP FST (add_stdo fd nm fs out).files = MAP FST fs.files`,
  rw[add_stdo_def]);

val inFS_fname_add_stdo = Q.store_thm("inFS_fname_add_stdo[simp]",
  `inFS_fname (add_stdo fd nm fs out) = inFS_fname fs`,
  rw[inFS_fname_def,FUN_EQ_THM]);

val STD_streams_stdout = Q.store_thm("STD_streams_stdout",
  `STD_streams fs ⇒ ∃out. stdout fs out`,
  rw[STD_streams_def,stdo_def] \\ rw[]);

val STD_streams_stderr = Q.store_thm("STD_streams_stderr",
  `STD_streams fs ⇒ ∃out. stderr fs out`,
  rw[STD_streams_def,stdo_def] \\ rw[]);

val STD_streams_add_stdout = Q.store_thm("STD_streams_add_stdout",
  `STD_streams fs ⇒ STD_streams (add_stdout fs out)`,
  rw[]
  \\ imp_res_tac STD_streams_stdout
  \\ rw[add_stdo_def]
  \\ SELECT_ELIM_TAC
  \\ rw[] >- metis_tac[]
  \\ rw[up_stdo_def]
  \\ match_mp_tac STD_streams_fsupdate \\ rw[]);

val STD_streams_add_stderr = Q.store_thm("STD_streams_add_stderr",
  `STD_streams fs ⇒ STD_streams (add_stderr fs out)`,
  rw[]
  \\ imp_res_tac STD_streams_stderr
  \\ rw[add_stdo_def]
  \\ SELECT_ELIM_TAC
  \\ rw[] >- metis_tac[]
  \\ rw[up_stdo_def]
  \\ match_mp_tac STD_streams_fsupdate \\ rw[]);

val validFD_fsupdate = Q.store_thm("validFD_fsupdate[simp]",
  `validFD fd (fsupdate fs fd' x y z) ⇔ validFD fd fs`,
  rw[fsupdate_def,validFD_def]);

val validFD_up_stdo = Q.store_thm("validFD_up_stdo[simp]",
  `validFD fd (up_stdo fd' fs out) ⇔ validFD fd fs`,
  rw[up_stdo_def]);

val validFD_add_stdo = Q.store_thm("validFD_add_stdo[simp]",
  `validFD fd (add_stdo fd' nm fs out) ⇔ validFD fd fs`,
  rw[add_stdo_def]);

val fsupdate_A_DELKEY = Q.store_thm("fsupdate_A_DELKEY",
  `fd ≠ fd' ⇒
   fsupdate (fs with infds updated_by A_DELKEY fd') fd k pos content =
   fsupdate fs fd k pos content with infds updated_by A_DELKEY fd'`,
  rw[fsupdate_def,ALOOKUP_ADELKEY]
  \\ CASE_TAC \\ CASE_TAC
  \\ rw[A_DELKEY_ALIST_FUPDKEY_comm]);

val up_stdo_A_DELKEY = Q.store_thm("up_stdo_A_DELKEY",
  `fd ≠ fd' ⇒
   up_stdo fd (fs with infds updated_by A_DELKEY fd') out =
   up_stdo fd fs out with infds updated_by A_DELKEY fd'`,
  rw[up_stdo_def,fsupdate_A_DELKEY]);

val stdo_A_DELKEY = Q.store_thm("stdo_A_DELKEY",
  `fd ≠ fd' ⇒
   stdo fd nm (fs with infds updated_by A_DELKEY fd') = stdo fd nm fs`,
  rw[stdo_def,FUN_EQ_THM,ALOOKUP_ADELKEY]);

val add_stdo_A_DELKEY = Q.store_thm("add_stdo_A_DELKEY",
  `fd ≠ fd' ⇒
   add_stdo fd nm (fs with infds updated_by A_DELKEY fd') out =
   add_stdo fd nm fs out with infds updated_by A_DELKEY fd'`,
  rw[add_stdo_def,up_stdo_A_DELKEY,stdo_A_DELKEY]);

val fastForwardFD_A_DELKEY_same = Q.store_thm("fastForwardFD_A_DELKEY_same[simp]",
  `fastForwardFD fs fd with infds updated_by A_DELKEY fd =
   fs with infds updated_by A_DELKEY fd`,
  rw[fastForwardFD_def]
  \\ Cases_on`ALOOKUP fs.infds fd` \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[libTheory.the_def]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[libTheory.the_def]
  \\ fs[IO_fs_component_equality,A_DELKEY_I])

val openFileFS_A_DELKEY_nextFD = Q.store_thm("openFileFS_A_DELKEY_nextFD",
  `nextFD fs ≤ 255 ⇒
   openFileFS f fs off with infds updated_by A_DELKEY (nextFD fs) = fs`,
  rw[IO_fs_component_equality,openFileFS_numchars,A_DELKEY_nextFD_openFileFS]);

val print_char_spec = Q.store_thm("print_char_spec",
  `CHAR c cv ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.print_char" (get_ml_prog_state())) [cv]
     (STDIO fs)
     (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stdout fs [c]))`,
  xcf "IO.print_char" (get_ml_prog_state())
  \\ reverse(Cases_on`STD_streams fs`) >- (fs[STDIO_def] \\ xpull)
  \\ xapp_spec write_char_STDIO_spec
  \\ imp_res_tac STD_streams_stdout
  \\ fs[stdo_def,get_file_content_def,PULL_EXISTS]
  \\ instantiate \\ xsimpl
  \\ simp[insert_atI_end]
  \\ simp[add_stdo_def,up_stdo_def]
  \\ SELECT_ELIM_TAC
  \\ simp[stdo_def]
  \\ xsimpl
  \\ metis_tac[stdout_v_thm,stdOut_def]);

val prerr_char_spec = Q.store_thm("prerr_char_spec",
  `CHAR c cv ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.prerr_char" (get_ml_prog_state())) [cv]
     (STDIO fs)
     (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stderr fs [c]))`,
  xcf "IO.prerr_char" (get_ml_prog_state())
  \\ reverse(Cases_on`STD_streams fs`) >- (fs[STDIO_def] \\ xpull)
  \\ xapp_spec write_char_STDIO_spec
  \\ imp_res_tac STD_streams_stderr
  \\ fs[stdo_def,get_file_content_def,PULL_EXISTS]
  \\ instantiate \\ xsimpl
  \\ simp[insert_atI_end]
  \\ simp[add_stdo_def,up_stdo_def]
  \\ SELECT_ELIM_TAC
  \\ simp[stdo_def]
  \\ xsimpl
  \\ metis_tac[stdErr_def,stderr_v_thm]);

val print_string_spec = Q.store_thm("print_string_spec",
  `!fs sv s.
    STRING_TYPE s sv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.print_string" (basis_st())) [sv]
    (STDIO fs)
    (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stdout fs (explode s)))`,
  xcf "IO.print_string" (basis_st()) >>
  fs[STDIO_def] \\ xpull \\
  imp_res_tac STD_streams_add_stdout \\
  pop_assum(qspec_then`explode s`mp_tac) \\ rw[] \\
  fs[IOFS_def,add_stdo_def,up_stdo_def,stdo_def] >> xpull >>
  `WORD (1w:word8) stdout_v` by metis_tac[stdout_v_thm,stdOut_def] >>
  xapp >> fs[get_file_content_validFD,IOFS_def] >> xsimpl >>
  imp_res_tac STD_streams_stdout >> fs[stdo_def] >>
  instantiate >>fs[ALOOKUP_validFD,get_file_content_def] >>
  xsimpl >> rw[] >>
  SELECT_ELIM_TAC \\ simp[] >>
  fs[wfFS_fsupdate,liveFS_fsupdate,get_file_content_fsupdate,insert_atI_end,
     LENGTH_explode,fsupdate_def,ALIST_FUPDKEY_ALOOKUP] >>
  rfs[] >> instantiate >> xsimpl);

val prerr_string_spec = Q.store_thm("prerr_string_spec",
  `!fs sv s.
    STRING_TYPE s sv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.prerr_string" (basis_st())) [sv]
    (STDIO fs)
    (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stderr fs (explode s)))`,
  xcf "IO.prerr_string" (basis_st()) >>
  fs[STDIO_def] \\ xpull \\
  imp_res_tac STD_streams_add_stderr \\
  pop_assum(qspec_then`explode s`mp_tac) \\ rw[] \\
  fs[IOFS_def,add_stdo_def,up_stdo_def,stdo_def] >> xpull >>
  `WORD (2w:word8) stderr_v` by metis_tac[stderr_v_thm,stdErr_def] >>
  xapp >> fs[get_file_content_validFD,IOFS_def] >> xsimpl >>
  imp_res_tac STD_streams_stderr >> fs[stdo_def] >>
  instantiate >>fs[ALOOKUP_validFD,get_file_content_def] >>
  xsimpl >> rw[] >>
  SELECT_ELIM_TAC \\ simp[] >>
  fs[wfFS_fsupdate,liveFS_fsupdate,get_file_content_fsupdate,insert_atI_end,
     LENGTH_explode,fsupdate_def,ALIST_FUPDKEY_ALOOKUP] >>
  rfs[] >> instantiate >> xsimpl);

val print_newline_spec = Q.store_thm("print_newline_spec",
  `!fs uv.
    UNIT_TYPE u uv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.print_newline" (basis_st())) [uv]
    (STDIO fs)
    (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stdout fs "\n"))`,
  xcf "IO.print_newline" (basis_st()) >>
  xmatch >> xsimpl >> fs[UNIT_TYPE_def] >> reverse(rw[]) >- EVAL_TAC >>
  reverse(Cases_on`STD_streams fs`) >- (fs[STDIO_def] \\ xpull) \\
  xapp_spec write_char_STDIO_spec >>
  imp_res_tac STD_streams_stdout \\
  first_assum(strip_assume_tac o SIMP_RULE std_ss [stdo_def]) \\
  fs[get_file_content_def,PULL_EXISTS] \\
  `WORD (1w:word8) stdout_v` by metis_tac[stdout_v_thm,stdOut_def] >>
  instantiate \\ xsimpl \\ rw[UNIT_TYPE_def] \\
  simp[insert_atI_end] \\
  rw[add_stdo_def,up_stdo_def] \\
  SELECT_ELIM_TAC \\ rw[] \\
  imp_res_tac stdo_UNICITY_R \\ rw[] \\ xsimpl \\ metis_tac[]);

val prerr_newline_spec = Q.store_thm("prerr_newline_spec",
  `!fs uv.
    UNIT_TYPE u uv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.prerr_newline" (basis_st())) [uv]
    (STDIO fs)
    (POSTv uv. &(UNIT_TYPE () uv) * STDIO (add_stderr fs "\n"))`,
  xcf "IO.prerr_newline" (basis_st()) >>
  xmatch >> xsimpl >> fs[UNIT_TYPE_def] >> reverse(rw[]) >- EVAL_TAC >>
  reverse(Cases_on`STD_streams fs`) >- (fs[STDIO_def] \\ xpull) \\
  xapp_spec write_char_STDIO_spec >>
  imp_res_tac STD_streams_stderr \\
  first_assum(strip_assume_tac o SIMP_RULE std_ss [stdo_def]) \\
  fs[get_file_content_def,PULL_EXISTS] \\
  `WORD (2w:word8) stderr_v` by metis_tac[stderr_v_thm,stdErr_def] >>
  instantiate \\ xsimpl \\ rw[UNIT_TYPE_def] \\
  simp[insert_atI_end] \\
  rw[add_stdo_def,up_stdo_def] \\
  SELECT_ELIM_TAC \\ rw[] \\
  imp_res_tac stdo_UNICITY_R \\ rw[] \\ xsimpl \\ metis_tac[]);

val inputLine_spec = Q.store_thm("inputLine_spec",
  `WORD (n2w fd : word8) fdv ∧ fd ≤ 255 ∧ IS_SOME (get_file_content fs fd)
   ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.inputLine" (get_ml_prog_state())) [fdv]
     (STDIO fs)
     (POSTv sov.
       &OPTION_TYPE STRING_TYPE (OPTION_MAP implode (lineFD fs fd)) sov *
       STDIO (lineForwardFD fs fd))`,
  strip_tac
  \\ xcf "IO.inputLine" (get_ml_prog_state()) >>
  xfun_spec `realloc`
    `∀arrv arr.
     app (p:'ffi ffi_proj) realloc [arrv] (W8ARRAY arrv arr)
       (POSTv v. W8ARRAY v (arr ++ (REPLICATE (LENGTH arr) 0w)))`
  >- (
    rw[] \\ first_x_assum match_mp_tac
    \\ ntac 5 (xlet_auto >- xsimpl)
    \\ xret \\ xsimpl
    \\ simp[DROP_REPLICATE] ) \\
  xlet_auto >- xsimpl \\
  xlet_auto >- xsimpl \\
  qpat_abbrev_tac`protect = STDIO fs` \\
  fs[IS_SOME_EXISTS,EXISTS_PROD] \\
  fs[lineFD_def,lineForwardFD_def] \\
  pairarg_tac \\ fs[] \\
  reverse IF_CASES_TAC \\ fs[] >- (
    xfun_spec`inputLine_aux`
      `∀arr arrv.
       0 < LENGTH arr ⇒
       app (p:'ffi ffi_proj) inputLine_aux [arrv;Litv(IntLit 0)]
       (STDIO fs * W8ARRAY arrv arr)
       (POSTv v. &OPTION_TYPE STRING_TYPE NONE v * STDIO fs)`
    >- (
      rw[Abbr`protect`]
      \\ first_x_assum match_mp_tac
      \\ xlet_auto >- xsimpl
      \\ xlet_auto >- xsimpl
      \\ xif
      \\ instantiate
      \\ xhandle`POSTe e. &EndOfFile_exn e * STDIO fs * W8ARRAY arrv arr`
      >- (
        (* TODO xlet_auto *)
        xlet`POSTe e. &EndOfFile_exn e * STDIO fs * W8ARRAY arrv arr`
        >- (
          fs[STDIO_def] \\ xpull
          \\ xapp
          \\ asm_exists_tac \\ fs[bumpFD_0]
          \\ mp_tac (SPEC_ALL (GSYM get_file_content_numchars))
          \\ rw[]
          \\ asm_exists_tac \\ fs[]
          \\ xsimpl
          \\ imp_res_tac get_file_content_eof \\ fs[]
          \\ rw[]
          \\ qexists_tac`THE(LTL ll)`
          \\ xsimpl )
        \\ xsimpl )
      \\ xcases
      \\ fs[EndOfFile_exn_def]
      \\ reverse conj_tac >- (EVAL_TAC \\ fs[])
      \\ `NUM 0 (Litv(IntLit 0))` by EVAL_TAC
      \\ xlet_auto >- xsimpl
      \\ xif
      \\ instantiate
      \\ xcon
      \\ xsimpl
      \\ fs[OPTION_TYPE_def])
    \\ xlet_auto >- xsimpl
    \\ xlet_auto >- xsimpl
    \\ xapp
    \\ xsimpl ) \\
  qabbrev_tac`arrmax = MAX 128 (2 * LENGTH l + 1)` \\
  qmatch_assum_rename_tac`get_file_content fs fd = SOME (content,pos)` \\
  xfun_spec `inputLine_aux`
    `∀pp arr i arrv iv fs.
     arr ≠ [] ∧ i ≤ LENGTH arr ∧ LENGTH arr < arrmax ∧
     NUM i iv ∧ pos ≤ pp ∧ pp ≤ LENGTH content ∧
     get_file_content fs fd = SOME (content,pp) ∧ i = pp - pos ∧
     EVERY ($~ o $= #"\n") (TAKE i (DROP pos content)) ∧
     i ≤ LENGTH l ∧ MAP (CHR o w2n) (TAKE i arr) = TAKE i l
     ⇒
     app (p:'ffi ffi_proj) inputLine_aux [arrv; iv]
       (STDIO fs * W8ARRAY arrv arr)
       (POSTv v.
        &(OPTION_TYPE STRING_TYPE (SOME (implode(l ++ "\n"))) v) *
        STDIO (forwardFD fs fd ((LENGTH l - i)+ if NULL r then 0 else 1)))`
  >- (
    qx_gen_tac`pp` \\
    `WF (inv_image ($< LEX $<) (λ(pp,(arr:word8 list)). (arrmax - LENGTH arr, LENGTH content - pp)))`
    by (
      match_mp_tac WF_inv_image \\
      match_mp_tac WF_LEX \\
      simp[] ) \\
    gen_tac \\
    qho_match_abbrev_tac`PC pp arr` \\
    qabbrev_tac`P = λ(pp,arr). PC pp arr` \\
    `∀x. P x` suffices_by simp[FORALL_PROD,Abbr`P`] \\
    qunabbrev_tac`PC` \\
    match_mp_tac(MP_CANON WF_INDUCTION_THM) \\
    asm_exists_tac \\ fs[] \\
    simp[FORALL_PROD,Abbr`P`] \\
    rpt strip_tac \\
    last_x_assum match_mp_tac \\
    xlet_auto >- xsimpl \\
    xlet_auto >- xsimpl \\
    reverse xif >- (
      qmatch_goalsub_rename_tac`W8ARRAY arrv arr` \\
      (* TODO: xlet_auto *)
      xlet`POSTv v. W8ARRAY v (arr ++ REPLICATE (LENGTH arr) 0w) * STDIO fs'`
      >- ( xapp \\ xsimpl )
      \\ xapp
      \\ xsimpl
      \\ instantiate
      \\ xsimpl
      \\ simp[TAKE_APPEND1]
      \\ simp[LEX_DEF]
      \\ Cases_on`LENGTH arr = 0` >- fs[]
      \\ simp[Abbr`arrmax`])
    \\ qmatch_asmsub_rename_tac`MAP _ (TAKE (pp-pos) arr2)`
    \\ qho_match_abbrev_tac`cf_handle _ _ _ _ (POSTv v. post v)`
    \\ reverse (xhandle`POST (λv. &(pp < LENGTH content) * post v)
        (λe. &(EndOfFile_exn e ∧ pp = LENGTH content)
            * W8ARRAY arrv arr2 * STDIO fs')`)
    >- (
      xcases \\ xsimpl
      \\ fs[EndOfFile_exn_def]
      \\ reverse conj_tac >- (EVAL_TAC \\ fs[])
      \\ xlet_auto >- xsimpl
      \\ xif
      \\ instantiate
      \\ xlet_auto >- xsimpl
      \\ xlet_auto >- xsimpl
      \\ xlet_auto >- xsimpl
      \\ xcon
      \\ simp[Abbr`post`]
      \\ fs[TAKE_LENGTH_ID_rwt]
      \\ (SPLITP_NIL_SND_EVERY
          |> SPEC_ALL |> EQ_IMP_RULE |> #2
          |> GEN_ALL |> SIMP_RULE std_ss []
          |> imp_res_tac)
      \\ fs[] \\ rveq
      \\ fs[OPTION_TYPE_def,implode_def,STRING_TYPE_def]
      \\ simp[STDIO_numchars]
      \\ xsimpl
      \\ fs[TAKE_LENGTH_ID_rwt] \\ rveq
      \\ fs[MAP_TAKE,LUPDATE_MAP]
      \\ qpat_x_assum`_ = DROP pos content`(SUBST1_TAC o SYM)
      \\ simp[LIST_EQ_REWRITE,EL_TAKE,EL_LUPDATE,EL_MAP]
      \\ rw[] \\ rw[EL_APPEND_EQN,EL_TAKE,EL_MAP] )
    >- xsimpl
    \\ fs[Abbr`post`]
    (* TODO xlet_auto *)
    \\ xlet `POST (λv. &(WORD ((n2w(ORD (EL pp content))):word8) v ∧
                         pp < LENGTH content)
                      * W8ARRAY arrv arr2 * STDIO (forwardFD fs' fd 1))
                  (λe. &(EndOfFile_exn e ∧ pp = LENGTH content)
                      * W8ARRAY arrv arr2 * STDIO fs')`
    >- (
      fs[STDIO_def]
      \\ xpull
      \\ xapp >>
      asm_exists_tac \\ fs[]
      \\ mp_tac (SPEC_ALL (Q.SPEC`fs'`(GSYM get_file_content_numchars)))
      \\ rw[]
      \\ asm_exists_tac \\ fs[]
      \\ xsimpl
      \\ imp_res_tac get_file_content_eof \\ fs[]
      \\ simp[bumpFD_numchars,bumpFD_0,bumpFD_forwardFD]
      \\ `pp < LENGTH content ⇒ fd ≠ 1 ∧ fd ≠ 2`
      by (
        fs[STD_streams_def]
        \\ rw[] \\ strip_tac \\ fs[get_file_content_def]
        \\ pairarg_tac \\ fs[] \\ rw[]
        \\ metis_tac[SOME_11,PAIR,prim_recTheory.LESS_REFL,FST,SND])
      \\ simp[STD_streams_forwardFD]
      \\ rw[]
      \\ qexists_tac`THE(LTL ll)`
      \\ xsimpl )
    >- xsimpl
    \\ xlet_auto >- xsimpl
    \\ xlet_auto >- xsimpl
    \\ xif
    >- (
      xlet_auto >- xsimpl
      \\ xlet_auto >- xsimpl
      \\ xcon
      >- (
        xsimpl
        \\ fs[OPTION_TYPE_def,implode_def,STRING_TYPE_def,ORD_BOUND]
        \\ qhdtm_x_assum`SPLITP`assume_tac
        \\ qispl_then[`(=)#"\n"`,`pp-pos`,`DROP pos content`]mp_tac SPLITP_TAKE_DROP
        \\ simp[EL_DROP]
        \\ impl_tac >- simp[CHAR_EQ_THM]
        \\ strip_tac \\ rveq
        \\ fs[TAKE_LENGTH_ID_rwt]
        \\ rfs[LENGTH_TAKE,TAKE_LENGTH_ID_rwt]
        \\ simp[DROP_DROP,NULL_EQ,DROP_NIL]
        \\ xsimpl
        \\ qpat_x_assum`_ = _ (DROP pos content)`(SUBST1_TAC o SYM)
        \\ simp[LIST_EQ_REWRITE,EL_TAKE,EL_LUPDATE,EL_MAP]
        \\ rw[] \\ rw[EL_APPEND_EQN,EL_TAKE,EL_MAP] )
      \\ xsimpl )
    \\ xlet_auto >- xsimpl
    \\ xapp
    \\ xsimpl
    \\ `pp+1 ≤ LENGTH content` by fs[]
    \\ instantiate
    \\ CONV_TAC SWAP_EXISTS_CONV
    \\ qexists_tac`forwardFD fs' fd 1`
    \\ simp[LEX_DEF]
    \\ xsimpl
    \\ fs[ORD_BOUND]
    \\ first_x_assum(qspec_then`_`kall_tac)
    \\ Cases_on`NULL r`
    >- (
      fs[NULL_EQ]
      \\ imp_res_tac SPLITP_NIL_SND_EVERY
      \\ rveq \\ fs[forwardFD_o,STDIO_numchars]
      \\ xsimpl
      \\ `pp + 1 - pos = (pp - pos) + 1` by fs[]
      \\ pop_assum SUBST_ALL_TAC
      \\ rewrite_tac[TAKE_SUM]
      \\ fs[]
      \\ conj_tac
      >- (
        simp[LIST_EQ_REWRITE,EL_MAP,EL_TAKE,EL_APPEND_EQN,DROP_DROP,EL_LUPDATE,EL_DROP,ORD_BOUND,CHR_ORD]
        \\ rw[] \\ rfs[]
        >- (
          qpat_x_assum`MAP _ _ =  _`mp_tac
          \\ simp[LIST_EQ_REWRITE,EL_MAP,EL_TAKE,EL_DROP] )
        \\ `x = pp - pos` by fs[]
        \\ rw[] )
      \\ simp[DROP_DROP]
      \\ simp[take1_drop,CHAR_EQ_THM] )
    \\ fs[forwardFD_o,STDIO_numchars]
    \\ xsimpl
    \\ conj_asm1_tac
    >- (
      CCONTR_TAC
      \\ `pp - pos = LENGTH l` by fs[]
      \\ imp_res_tac SPLITP_JOIN
      \\ fs[NULL_EQ]
      \\ `EL (pp - pos) (DROP pos content) = HD r` by ( simp[EL_APPEND2] )
      \\ `pp = LENGTH l + pos` by fs[]
      \\ `EL pp content = HD r` by (
        qpat_x_assum`_ = HD r` (SUBST1_TAC o SYM)
        \\ simp[EL_DROP] )
      \\ imp_res_tac SPLITP_IMP
      \\ rfs[NULL_EQ]
      \\ pop_assum mp_tac
      \\ simp[CHAR_EQ_THM] \\ fs[] )
    \\ conj_tac
    >- (
      qpat_x_assum`MAP _ _ = _`mp_tac
      \\ simp[LIST_EQ_REWRITE,LENGTH_TAKE_EQ,EL_MAP,EL_TAKE,EL_LUPDATE]
      \\ rw[]
      \\ rw[ORD_BOUND,CHR_ORD]
      \\ imp_res_tac SPLITP_JOIN
      \\ `EL (pp - pos) l = EL (pp - pos) (DROP pos content)` by simp[EL_APPEND_EQN]
      \\ pop_assum SUBST1_TAC
      \\ simp[EL_DROP] )
    \\ `pp + 1 - pos = (pp - pos) + 1` by fs[]
    \\ pop_assum SUBST_ALL_TAC
    \\ rewrite_tac[TAKE_SUM]
    \\ simp[]
    \\ simp[take1_drop,EL_DROP,CHAR_EQ_THM] )
  \\ xlet_auto >- xsimpl
  \\ xlet_auto >- xsimpl
  \\ xapp
  \\ xsimpl
  \\ simp[Abbr`arrmax`,Abbr`protect`]
  \\ CONV_TAC(RESORT_EXISTS_CONV List.rev)
  \\ qexists_tac`pos` \\ simp[]
  \\ instantiate
  \\ xsimpl
  \\ EVAL_TAC);

(*
unfinished proof for previous version of inputLine

val find_newline_spec = Q.store_thm("find_newline_spec",
 `!s sv lv i iv.
  STRING_TYPE (strlit s) sv ==>
  NUM (LENGTH s) lv ==>
  NUM i iv ==>
  EVERY ($~ ∘ ((=) #"\n")) (TAKE i s) ==>
  app (p:'ffi ffi_proj) ^(fetch_v "IO.find_newline" (basis_st())) [sv;iv;lv]
  emp
  (POSTv nv. SEP_EXISTS n. &(NUM n nv /\ EVERY ($~ ∘ ((=) #"\n")) (TAKE n s) /\
    n <= LENGTH s /\
    (n < LENGTH s ==> EL n s = #"\n")))`,
  Induct_on `(STRLEN s - i)` >>
  xcf "IO.find_newline" (basis_st()) >>
  xlet_auto >> xsimpl >>
  xif >-(instantiate >> xvar >> xsimpl >> instantiate >> rfs[TAKE_LENGTH_TOO_LONG]) >>
  instantiate >>
  NTAC 2 (xlet_auto >> xsimpl) >>
  xif >-(xvar >> xsimpl >> instantiate) >>
  xlet_auto >> xsimpl >> xapp >> fs[] >>
  qexists_tac `i+1` >> fs[TAKE_EL_SNOC,EVERY_SNOC]);

val split_newline_spec = Q.store_thm("split_newline",
  `!s sv line lrest line lrest.
    STRING_TYPE s sv ⇒
    app (p:'ffi ffi_proj) ^(fetch_v "IO.split_newline" (basis_st())) [sv]
    emp
    (POSTv rv. SEP_EXISTS line. SEP_EXISTS lrest.
      &((line, lrest) = SPLITP ((=) #"\n") (explode s) /\
      PAIR_TYPE STRING_TYPE STRING_TYPE
                (implode line, implode lrest) rv))`,
  xcf "IO.split_newline" (basis_st()) >> cases_on`s` >>
  cases_on`SPLITP ($= #"\n") s'` >> fs[] >>
  rpt (xlet_auto >> xsimpl) >>
  xcon >> xsimpl >> fs[PAIR_TYPE_def,implode_def] >>
  cases_on`n = STRLEN s'`
  >-(fs[TAKE_LENGTH_TOO_LONG,SPLITP_NIL_SND_EVERY] >>
     imp_res_tac SPLITP_NIL_SND_EVERY >> fs[] >>
     `substring (strlit s') 0 (STRLEN s') = strlit q` by
     (PURE_REWRITE_TAC [GSYM strlen_def] >> fs[substring_full]) >>
     `substring (strlit s') (STRLEN s') 0 = strlit r` by
     (PURE_REWRITE_TAC [GSYM strlen_def] >> fs[substring_too_long]) >>
     rw[] >> fs[]) >>
  `#"\n" = EL n s'` by fs[] >> imp_res_tac SPLITP_TAKE_DROP >>
  rfs[substring_def] >> fs[TAKE_SEG,DROP_SEG]);

val inputLine_spec = Q.store_thm("inputLine_spec",
 `!fd fdv lbuf lbufv pos content line.
  WORD (n2w fd : word8) fdv ∧ fd <= 255 ∧
  STRING_TYPE (strlit lbuf) lbufv ∧
  get_file_content fs fd = SOME(content, pos) ∧
  line = FST(SPLITP ((=) #"\n") (lbuf ++ content))
  ⇒
 app (p:'ffi ffi_proj) ^(fetch_v "IO.inputLine" (basis_st())) [fdv; lbufv]
    (STDIO fs)
    (POSTv rv.
       SEP_EXISTS lrest k.
       &(PAIR_TYPE STRING_TYPE STRING_TYPE (implode line, implode lrest) rv /\
         lbuf ++ DROP pos content = line ++ lrest ++ DROP (pos + k) content) *
       STDIO (bumpFD fd fs k))`,
 xcf "IO.inputLine" (basis_st()) >>
 (* TODO: xfun_spec is very slow here, so this more careful version instead: *)
 (* could the normal version be made faster? *)
 xfun_rec_core
 \\ qx_gen_tac`inputLine_aux`
 \\ disch_then ((fn(curried_th,spec_th)=> assume_tac curried_th \\ mp_tac spec_th) o CONJ_PAIR)
 \\ rpt(CHANGED_TAC (disch_then (mp_tac o CONV_RULE reduce_conv o PURE_ONCE_REWRITE_RULE[cf_def])))
 \\ reverse (disch_then (fn spec_th => qsuff_tac `
 !pos' fs' lacc laccv.
 LIST_TYPE STRING_TYPE (MAP strlit lacc) laccv ⇒
 get_file_content fs' fd = SOME(content, pos') ⇒
 let line = CONCAT (REVERSE lacc) ++ FST(SPLITP ((=) #"\n") (DROP pos' content)) in
 app (p:'ffi ffi_proj) inputLine_aux [laccv]
   (STDIO fs')
   (POSTv rv. SEP_EXISTS lbuf. SEP_EXISTS k.
      &(PAIR_TYPE STRING_TYPE STRING_TYPE (implode line, implode lbuf) rv /\
        lbuf ++ DROP (pos' + k) content =
        SND (SPLITP ((=) #"\n") (DROP pos' content))) *
      STDIO (bumpFD fd fs' k))` THENL [strip_tac, assume_tac spec_th]))
 >-(
    qx_gen_tac`pos'` >>
    `?N. LENGTH content - pos' <= N` by
        (qexists_tac `LENGTH content -pos'` >> fs[]) >>
    first_x_assum mp_tac >> qid_spec_tac`pos'` >>
    Induct_on`N` >>(
    rw[] >> xapp >> fs[] >>
    xlet_auto >> fs[] >> xsimpl >>
    fs[STDIO_def,IOFS_def,IOFS_iobuff_def] >>
    xpull >> rename [`W8ARRAY _ bdef`] >>
    Cases_on `bdef` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: t` >>
    Cases_on `t` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: t'` >>
    Cases_on `t'` >> fs[] >> qmatch_goalsub_abbrev_tac`h1 :: h2 :: h3 :: rest` >>
    PURE_REWRITE_TAC[GSYM iobuff_loc_def] >>
    xlet_auto
    >-(fs[] >> xsimpl >> rw[] >> instantiate >> xsimpl)
    >-(xsimpl >> fs[get_file_content_def,InvalidFD_exn_def]) >>
    xlet_auto >- xsimpl >>
    xif
    >-(NTAC 2 (xlet_auto >- xsimpl) >>
       xcon >> xsimpl >> fs[eof_def] >> pairarg_tac >> fs[] >>
       fs[get_file_content_def] >> rw[] >>
       fs[DROP_LENGTH_TOO_LONG,implode_def,SPLITP,PAIR_TYPE_def] >>
       qexists_tac `0` >> qexists_tac`THE (LTL ll)` >>
       fs[bumpFD_def,wfFS_def,liveFS_def,STD_streams_def] >>
       xsimpl >> qexists_tac `inp` >>
       fs[concat_def,MAP_REVERSE,STRING_TYPE_def,ALIST_FUPDKEY_unchanged] >>
       strip_tac
       >-(qmatch_abbrev_tac`CONCAT (REVERSE l1) = CONCAT (REVERSE l2)` >>
          `l1 = l2` suffices_by fs[] >> unabbrev_all_tac >>
          fs[MAP_MAP_o,MAP_EQ_ID]) >>
       cases_on`ll` >> imp_res_tac always_thm >> fs[])
    )
    >-(`eof fd (fs' with numchars := ll) = SOME T` by
        (fs[eof_def,get_file_content_def] >> rpt (pairarg_tac >> fs[]))) >>
    xlet_auto >- xsimpl >>
    xlet_auto >-(xsimpl >> rw[] >> instantiate >> xsimpl) >>
    NTAC 3 (xlet_auto >- xsimpl) >>
    xif
    >-(xlet_auto >-(xcon >> xsimpl) >>
       xapp >> xsimpl >>
       fs[GSYM get_file_content_numchars] >> rw[] >>
       map_every qexists_tac [`emp`,`pos' + nr`,`line :: lacc`,
                              `bumpFD fd (fs' with numchars := ll) nr`] >>
       fs[bumpFD_numchars,GSYM get_file_content_numchars,
          LIST_TYPE_def,PAIR_TYPE_def,implode_def] >>
       imp_res_tac get_file_content_bumpFD >> fs[] >> rw[]
       >-(qexists_tac`THE (LTL ll)` >>
          fs[GSYM STD_streams_numchars,STD_streams_bumpFD,GSYM bumpFD_numchars] >>
          xsimpl) >>
       instantiate >> qexists_tac`x' + nr` >> qexists_tac`x''` >>
       xsimpl >> fs[bumpFD_o,GSYM STD_streams_numchars] >> xsimpl >>
       fs[MAP_TAKE,TAKE_APPEND,TAKE_TAKE,LENGTH_MAP,LENGTH_DROP,
          GSYM MAP_o, MAP_APPEND,TAKE_TAKE] >>
       fs[MAP_MAP_o,CHR_w2n_n2w_ORD] >>
       fs[TAKE_TAKE_MIN,LENGTH_TAKE,LENGTH_DROP] >>
       `MIN nr (STRLEN content − pos') = nr` by fs[MIN_DEF] >>
       fs[GSYM TAKE_APPEND,LENGTH_TAKE_EQ_MIN,MIN_DEF] >>
       `SPLITP ($= #"\n") (TAKE nr (DROP pos' content)) = (line, "")` by fs[] >>
       imp_res_tac SPLITP_NIL_SND_EVERY >>
       fs[SND_SPLITP_DROP,GSYM DROP_DROP_T] >>
       imp_res_tac FST_SPLITP_DROP >> rw[]
    ) >>
    xlet_auto >-(xcon >> xsimpl) >>
    (* TODO: xlet_auto *)
    xlet`POSTv v. &STRING_TYPE (extract (implode lrest) 1 NONE) v *
          W8ARRAY (Loc 1)
           (0w::n2w nr::h3::
                (MAP (n2w ∘ ORD) (TAKE nr (DROP pos'' content')) ⧺
                 DROP nr rest)) *
          IOx fs_ffi_part (bumpFD fd (fs' with numchars := ll) nr)`
    >-(xapp >> xsimpl >>
       qexists_tac`NONE` >> instantiate >> fs[OPTION_TYPE_def,implode_def]) >>
    xlet_auto >- (xcon >> xsimpl) >>
    xlet_auto >- (xcon >> xsimpl) >>
    fs[implode_def] >>
    PURE_REWRITE_TAC[GSYM LIST_TYPE_def] >>
    `LIST_TYPE STRING_TYPE (strlit "\n" :: strlit line ::MAP strlit lacc) v''''`
    by fs[LIST_TYPE_def,STRING_TYPE_def] >> rfs[] >>
    NTAC 2 (xlet_auto >- xsimpl) >>
    xcon >> xsimpl >>
    fs[bumpFD_numchars,PAIR_TYPE_def] >>
    CONV_TAC(RESORT_EXISTS_CONV List.rev) >>
    qexists_tac`THE (LTL ll)` >> qexists_tac`nr` >> xsimpl >>
    fs[concat_def]
    qexists_tac`explode (extract (strlit lrest) 1 NONE)` >>
    fs[GSYM get_file_content_numchars] >>
    `pos' = pos''` by fs[] >>
    `content' = content` by fs[] >> rfs[] >>
    fs[GSYM STD_streams_numchars,STD_streams_bumpFD,GSYM bumpFD_numchars] >>
    fs[MAP_TAKE,TAKE_APPEND,TAKE_TAKE,LENGTH_MAP,LENGTH_DROP,
          GSYM MAP_o, MAP_APPEND,TAKE_TAKE] >>
    fs[MAP_MAP_o,CHR_w2n_n2w_ORD] >>
    fs[GSYM implode_def, implode_explode] >> fs[implode_def] \\
    rveq \\
    qmatch_goalsub_abbrev_tac`SPLITP _ ls` \\
    `nr ≤ LENGTH ls` by simp[Abbr`ls`] \\
    simp[GSYM DROP_DROP_T] \\
    fs[MAP_REVERSE,MAP_MAP_o,o_DEF] \\
    fs[STRING_TYPE_def] \\
    `extract (strlit lrest) 1 NONE = implode (TL lrest)` by (
      simp[extract_def,substring_def,implode_def]
      \\ Cases_on`LENGTH lrest = 1`
      >- (pop_assum mp_tac \\ rw[LENGTH_EQ_NUM_compute] \\ rw[] \\ rw[SEG])
      \\ Cases_on`LENGTH lrest = 0` >- fs[]
      \\ `¬(LENGTH lrest ≤ 1)` by decide_tac
      \\ simp[SEG_TAKE_BUTFISTN,TAKE_LENGTH_ID_rwt]
      \\ simp[DROP_FUNPOW_TL]
      \\ Cases_on`lrest` \\ fs[TL_T_def]) \\
    fs[] \\
    qpat_x_assum`_ = SPLITP _ _`(assume_tac o SYM) \\
    imp_res_tac SPLITP_IMP \\
    first_x_assum(qspec_then`_`kall_tac) \\
    first_x_assum(qspec_then`_`kall_tac) \\
    rfs[NULL_EQ] \\
    pop_assum(assume_tac o SYM) \\ fs[] \\
    Cases_on`SPLITP ($= #"\n") ls` \\ fs[] \\
    SPLITP_IMP

    fs[extract_def,substring_def,implode_def,concat_def] >>
    PURE_REWRITE_TAC [Once(GSYM (Q.SPECL [`nr`,`DROP pos' content`] TAKE_DROP))]
    fs[TAKE_APPEND,TAKE_TAKE_MIN,LENGTH_TAKE,LENGTH_DROP] >>
    `MIN nr (STRLEN content' − pos'') = nr` by fs[MIN_DEF] >> fs[] >>
    fs[SPLITP_APPEND] >>
    fs[STRING_TYPE_def] >> rveq >>
    IF_CASES_TAC \\ fs[STRING_TYPE_def,MAP_REVERSE,MAP_MAP_o,o_DEF]

    FULL_CASE_TAC >>
    FULL_CASE_TAC >>
    fs[GSYM DROP_DROP_T] >>
    cheat
    ) >>
  xlet_auto >- (xsimpl >> fs[PAIR_TYPE_def] >> rw[] >> instantiate) >>
  NTAC 3 (xlet_auto >- xsimpl) >>
  xif
  >-(
     xlet_auto >-(xcon >> xsimpl) >>
    `LIST_TYPE STRING_TYPE (MAP strlit []) v` by fs[LIST_TYPE_def] >>
    res_tac >> fs[] >>
    xlet_auto
    (* type error? *)
    xlet`(POSTv rv.
            SEP_EXISTS lbuf k.
              &(PAIR_TYPE STRING_TYPE STRING_TYPE
                  (implode (FST (SPLITP ($= #"\n") (DROP pos content))),
                   implode lbuf) rv ∧
                lbuf ++ (DROP (k + pos) content) =
                SND (SPLITP ($= #"\n") (DROP pos content))) *
              STDIO (bumpFD fd fs k))` >>
    >- cheat >>
    xlet_auto >- xsimpl >>
    xlet_auto >-(xcon >> xsimpl) >>
    xlet_auto >- xsimpl >>
    xlet_auto >-(xcon >> xsimpl) >>
    xlet_auto >-(xcon >> xsimpl) >>
    `LIST_TYPE STRING_TYPE (strlit line ::
                            strlit (FST (SPLITP ($= #"\n") (DROP pos content))) :: []) v'''`
                           by fs[LIST_TYPE_def,implode_def] >> rfs[] >>
    xlet_auto >- xsimpl >>
    xcon >> xsimpl >>
    cheat
    ) >>
 xlet_auto
 >-(xsimpl >> rw[] >> fs[PAIR_TYPE_def,implode_def] >> instantiate) >>
 NTAC 3 (xlet_auto >- xsimpl) >>
 xif
 >-(xlet_auto >-(xcon >> xsimpl) >>
    cheat) >>
 xlet_auto >- (xcon >> xsimpl) >>
 `OPTION_TYPE NUM NONE (Conv (SOME ("NONE",TypeId (Short "option"))) []) `
    by fs[OPTION_TYPE_def] >>
 xlet_auto >- xsimpl >>
 NTAC 3 (xlet_auto >-(xcon >> xsimpl)) >>
 `LIST_TYPE STRING_TYPE (strlit line :: strlit "\n" :: []) v'''`
      by fs[LIST_TYPE_def,implode_def] >> rfs[] >>
  xlet_auto >- xsimpl >>
  xcon >> xsimpl >>
  fs[PAIR_TYPE_def] >>
  qexists_tac`explode (extract (implode lrest) 1 NONE)` >>
  qexists_tac`0` >>
  fs[implode_def,bumpFD_def,explode_def] >>
  cheat);
*)

val inputLines_spec = Q.store_thm("input_lines_spec",
  `WORD ((n2w fd):word8) fdv ∧ fd ≤ 255 ∧
   get_file_content fs fd = SOME (content,pos)
   ⇒
   app (p:'ffi ffi_proj)
     ^(fetch_v "IO.inputLines"(get_ml_prog_state())) [fdv]
     (STDIO fs)
     (POSTv fcv.
       &LIST_TYPE STRING_TYPE
         (MAP (\x. strcat (implode x) (implode "\n"))
            (splitlines (DROP pos content))) fcv *
       STDIO (fastForwardFD fs fd))`,
  map_every qid_spec_tac[`fs`] \\
  Induct_on`splitlines (DROP pos content)` \\ rw[]
  >- (
    qpat_x_assum`[] = _`(assume_tac o SYM) \\ fs[DROP_NIL]
    \\ `LENGTH content - pos = 0` by simp[]
    \\ pop_assum SUBST1_TAC
    \\ `DROP pos content = []` by fs[DROP_NIL]
    \\ xcf"IO.inputLines"(get_ml_prog_state())
    \\ `IS_SOME (get_file_content fs fd)` by fs[IS_SOME_EXISTS]
    \\ xlet_auto >- xsimpl
    \\ rfs[lineFD_def,OPTION_TYPE_def]
    \\ xmatch
    \\ xcon
    \\ simp[lineForwardFD_def,fastForwardFD_0]
    \\ xsimpl
    \\ fs[LIST_TYPE_def])
  \\ qpat_x_assum`_::_ = _`(assume_tac o SYM) \\ fs[]
  \\ xcf"IO.inputLines"(get_ml_prog_state())
  \\ `IS_SOME (get_file_content fs fd)` by fs[IS_SOME_EXISTS]
  \\ xlet_auto >- xsimpl
  \\ rfs[lineFD_def]
  \\ imp_res_tac splitlines_next
  \\ rveq
  \\ `pos < LENGTH content`
  by ( CCONTR_TAC \\ fs[NOT_LESS,GSYM GREATER_EQ,GSYM DROP_NIL] )
  \\ fs[DROP_DROP_T]
  \\ pairarg_tac \\ fs[OPTION_TYPE_def,implode_def,STRING_TYPE_def] \\ rveq
  \\ xmatch
  \\ fs[lineForwardFD_def]
  \\ imp_res_tac splitlines_CONS_FST_SPLITP \\ rfs[] \\ rveq
  \\ qmatch_goalsub_abbrev_tac`forwardFD fs fd n`
  \\ first_x_assum(qspecl_then[`pos+n`,`content`]mp_tac)
  \\ impl_keep_tac
  >- (
    simp[Abbr`n`]
    \\ rw[ADD1]
    \\ fs[NULL_EQ]
    \\ imp_res_tac SPLITP_NIL_SND_EVERY
    \\ rveq
    \\ simp[DROP_LENGTH_TOO_LONG] )
  \\ disch_then(qspec_then`forwardFD fs fd n`mp_tac)
  \\ simp[]
  \\ strip_tac \\ fs[Abbr`n`,NULL_EQ]
  \\ xlet_auto >- xsimpl
  \\ xcon
  \\ xsimpl
  \\ simp[forwardFD_o,STDIO_numchars,LIST_TYPE_def]
  \\ fs[strcat_thm,implode_def]
  \\ qmatch_goalsub_abbrev_tac`forwardFD fs fd n`
  \\ `n ≤ LENGTH content - pos` suffices_by (
    simp[fastForwardFD_forwardFD] \\ xsimpl)
  \\ imp_res_tac IS_PREFIX_LENGTH
  \\ fs[] \\ rw[Abbr`n`] \\ fs[]
  \\ Cases_on`LENGTH h = LENGTH content - pos` \\ fs[]
  \\ imp_res_tac SPLITP_JOIN
  \\ pop_assum(mp_tac o Q.AP_TERM`LENGTH`) \\ simp[]
  \\ Cases_on`LENGTH r = 0` \\ simp[] \\ fs[] );

val all_lines_def = Define
  `all_lines fs fname =
    MAP (\x. strcat (implode x) (implode "\n"))
          (splitlines (THE (ALOOKUP fs.files fname)))`

val concat_all_lines = Q.store_thm("concat_all_lines",
  `concat (all_lines fs fname) = implode (THE (ALOOKUP fs.files fname)) ∨
   concat (all_lines fs fname) = implode (THE (ALOOKUP fs.files fname)) ^ str #"\n"`,
  rw[all_lines_def] \\
  qspec_tac(`THE (ALOOKUP fs.files fname)`,`ls`) \\
  Induct_on`splitlines ls` \\ rw[] \\
  pop_assum(assume_tac o SYM) \\
  fs[splitlines_eq_nil,concat_cons]
  >- EVAL_TAC \\
  imp_res_tac splitlines_next \\ rw[] \\
  first_x_assum(qspec_then`DROP (SUC (LENGTH h)) ls`mp_tac) \\
  rw[] \\ rw[]
  >- (
    Cases_on`LENGTH h < LENGTH ls` \\ fs[] >- (
      disj1_tac \\
      rw[strcat_thm] \\ AP_TERM_TAC \\
      fs[IS_PREFIX_APPEND,DROP_APPEND,DROP_LENGTH_TOO_LONG,ADD1] ) \\
    fs[DROP_LENGTH_TOO_LONG] \\
    fs[IS_PREFIX_APPEND,strcat_thm] \\ rw[] \\ fs[] \\
    EVAL_TAC )
  >- (
    disj2_tac \\
    rw[strcat_thm] \\
    AP_TERM_TAC \\ rw[] \\
    Cases_on`LENGTH h < LENGTH ls` \\
    fs[IS_PREFIX_APPEND,DROP_APPEND,ADD1,DROP_LENGTH_TOO_LONG]  \\
    qpat_x_assum`strlit [] = _`mp_tac \\ EVAL_TAC ));

val _ = overload_on("hasFreeFD",``λfs. CARD (set (MAP FST fs.infds)) ≤ 255``);

val inputLinesFrom_spec = Q.store_thm("inputLinesFrom_spec",
  `FILENAME f fv /\ hasFreeFD fs
   ⇒
   app (p:'ffi ffi_proj) ^(fetch_v"IO.inputLinesFrom"(get_ml_prog_state()))
     [fv]
     (STDIO fs)
     (POSTv sv. &OPTION_TYPE (LIST_TYPE STRING_TYPE)
            (if inFS_fname fs (File f) then
               SOME(all_lines fs (File f))
             else NONE) sv
             * STDIO fs)`,
  xcf"IO.inputLinesFrom"(get_ml_prog_state())
  \\ reverse(xhandle`POST
       (λv. &OPTION_TYPE (LIST_TYPE STRING_TYPE)
         (if inFS_fname fs (File f)
          then SOME(all_lines fs (File f))
          else NONE) v * STDIO fs)
       (λe. &(BadFileName_exn e ∧ ¬inFS_fname fs (File f)) * STDIO fs)`)
  >- (xcases \\ fs[BadFileName_exn_def]
      \\ reverse conj_tac >- (EVAL_TAC \\ rw[])
      \\ xcon \\ xsimpl \\ fs[ml_translatorTheory.OPTION_TYPE_def])
  >- xsimpl
  \\ `CARD (set (MAP FST fs.infds)) < 256` by fs[]
  \\ reverse(Cases_on`STD_streams fs`)
  >- ( fs[STDIO_def] \\ xpull )
  \\ xlet_auto_spec (SOME (SPEC_ALL openIn_STDIO_spec))
  >- (
    xsimpl
    \\ fs[nextFD_numchars,openFileFS_fupd_numchars,inFS_fname_numchars,GSYM validFD_numchars]
    \\ CONV_TAC SWAP_EXISTS_CONV
    \\ qexists_tac`ll` \\ xsimpl )
  >- (
    xsimpl
    \\ rw[inFS_fname_numchars]
    \\ qexists_tac`ll` \\ xsimpl )
  \\ drule (GEN_ALL ALOOKUP_inFS_fname_openFileFS_nextFD)
  \\ imp_res_tac nextFD_leX
  \\ disch_then(qspec_then`0`mp_tac) \\ rw[]
  \\ qmatch_assum_abbrev_tac`validFD fd fso`
  \\ `∃c. get_file_content fso fd = SOME (c,0)`
  by (
    fs[get_file_content_def,validFD_def,Abbr`fso`,openFileFS_files]
    \\ imp_res_tac inFS_fname_ALOOKUP_EXISTS \\ fs[] )
  \\ xlet_auto >- xsimpl
  \\ qmatch_goalsub_abbrev_tac`STDIO fsob`
  \\ qspecl_then[`fd`,`fsob`,`wv`]mp_tac close_STDIO_spec
  \\ impl_tac >- (
    fs[STD_streams_def]
    \\ `¬(fd = 0 ∨ fd = 1 ∨ fd = 2)` suffices_by fs[]
    \\ metis_tac[nextFD_NOT_MEM,ALOOKUP_MEM] )
  \\ strip_tac
  \\ xlet_auto >- xsimpl
  >- ( xsimpl \\ simp[Abbr`fsob`] )
  \\ reverse xcon \\ xsimpl
  \\ fs[OPTION_TYPE_def]
  \\ fs[all_lines_def]
  \\ fs[get_file_content_def]
  \\ pairarg_tac \\ fs[]
  \\ fs[Abbr`fso`,openFileFS_files]
  \\ rveq \\ fs[]
  \\ qmatch_goalsub_abbrev_tac`STDIO fs'`
  \\ `fs' = fs` suffices_by ( rw[] \\ xsimpl)
  \\ unabbrev_all_tac
  \\ simp[fastForwardFD_def,A_DELKEY_ALIST_FUPDKEY,o_DEF,
          libTheory.the_def, openFileFS_numchars,
          IO_fs_component_equality,openFileFS_files]);

val print_list_spec = Q.store_thm("print_list_spec",
  `∀ls lv fs out. LIST_TYPE STRING_TYPE ls lv ⇒
   app (p:'ffi ffi_proj) ^(fetch_v "IO.print_list" (get_ml_prog_state())) [lv]
     (STDIO fs)
     (POSTv v. &UNIT_TYPE () v * STDIO (add_stdout fs (FLAT (MAP explode ls))))`,
  Induct \\ rw[LIST_TYPE_def] \\ xcf "IO.print_list" (get_ml_prog_state())
  \\ (reverse(Cases_on`STD_streams fs`) >- (fs[STDIO_def] \\ xpull))
  \\ xmatch
  >- (xcon \\ fs[STD_streams_stdout,add_stdo_nil] \\ xsimpl)
  \\ rename1`STRING_TYPE s sv`
  (* TODO: fix xlet_auto to deal with STDIO properly *)
  \\ xlet`POSTv uv.  &UNIT_TYPE () uv *
            STDIO (add_stdout fs (explode s))`
  \\ xapp \\ xsimpl
  \\ map_every qexists_tac [`emp`,`add_stdout fs (explode s)`]
  \\ xsimpl
  \\ imp_res_tac STD_streams_stdout
  \\ imp_res_tac add_stdo_o
  \\ xsimpl);

val linesFD_def = Define`
 linesFD fs fd =
   case get_file_content fs fd of
   | NONE => []
   | SOME (content,pos) =>
       MAP (λx. x ++ "\n")
         (splitlines (DROP pos content))`;

val linesFD_nil_lineFD_NONE = Q.store_thm("linesFD_nil_lineFD_NONE",
  `linesFD fs fd = [] ⇔ lineFD fs fd = NONE`,
  rw[lineFD_def,linesFD_def]
  \\ CASE_TAC \\ fs[]
  \\ CASE_TAC \\ fs[]
  \\ pairarg_tac \\ fs[DROP_NIL]);

val linesFD_cons_imp = Q.store_thm("linesFD_cons_imp",
  `linesFD fs fd = ln::ls ⇒
   lineFD fs fd = SOME ln ∧
   linesFD (lineForwardFD fs fd) fd = ls`,
  simp[linesFD_def,lineForwardFD_def]
  \\ CASE_TAC \\ CASE_TAC
  \\ strip_tac
  \\ rename1`_ = SOME (content,off)`
  \\ conj_asm1_tac
  >- (
    simp[lineFD_def]
    \\ Cases_on`DROP off content` \\ rfs[DROP_NIL]
    \\ conj_asm1_tac
    >- ( CCONTR_TAC \\ fs[DROP_LENGTH_TOO_LONG] )
    \\ fs[splitlines_def,FIELDS_def]
    \\ pairarg_tac \\ fs[]
    \\ every_case_tac \\ fs[] \\ rw[]
    \\ fs[NULL_EQ]
    \\ imp_res_tac SPLITP_NIL_IMP \\ fs[] \\ rw[]
    >- ( Cases_on`FIELDS ($= #"\n") t` \\ fs[] )
    >- ( Cases_on`FIELDS ($= #"\n") (TL r)` \\ fs[] ))
  \\ reverse IF_CASES_TAC \\ fs[DROP_LENGTH_TOO_LONG]
  \\ pairarg_tac \\ fs[]
  \\ Cases_on`splitlines (DROP off content)` \\ fs[] \\ rveq
  \\ AP_TERM_TAC
  \\ imp_res_tac splitlines_next
  \\ fs[DROP_DROP_T,ADD1,NULL_EQ]
  \\ imp_res_tac splitlines_CONS_FST_SPLITP \\ rfs[]
  \\ IF_CASES_TAC \\ fs[] \\ rw[]
  \\ fs[SPLITP_NIL_SND_EVERY]
  \\ rveq \\ fs[DROP_LENGTH_TOO_LONG]);

val linesFD_openFileFS_nextFD = Q.store_thm("linesFD_openFileFS_nextFD",
  `inFS_fname fs (File f) ∧ nextFD fs ≤ 255 ⇒
   linesFD (openFileFS f fs 0) (nextFD fs) = MAP explode (all_lines fs (File f))`,
  rw[linesFD_def,get_file_content_def,ALOOKUP_inFS_fname_openFileFS_nextFD]
  \\ rw[all_lines_def]
  \\ imp_res_tac inFS_fname_ALOOKUP_EXISTS
  \\ fs[MAP_MAP_o,o_DEF,GSYM mlstringTheory.implode_STRCAT]);

val STD_streams_lineForwardFD = Q.store_thm("STD_streams_lineForwardFD",
  `fd ≠ 1 ∧ fd ≠ 2 ⇒
   (STD_streams (lineForwardFD fs fd) ⇔ STD_streams fs)`,
  rw[lineForwardFD_def]
  \\ CASE_TAC \\ fs[]
  \\ CASE_TAC \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ IF_CASES_TAC \\ fs[]
  \\ simp[STD_streams_forwardFD]);

val STD_streams_fastForwardFD = Q.store_thm("STD_streams_fastForwardFD",
  `fd ≠ 1 ∧ fd ≠ 2 ⇒
   (STD_streams (fastForwardFD fs fd) ⇔ STD_streams fs)`,
  rw[fastForwardFD_def]
  \\ Cases_on`ALOOKUP fs.infds fd` \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[libTheory.the_def]
  \\ EQ_TAC \\ rw[STD_streams_def,option_case_eq,ALIST_FUPDKEY_ALOOKUP,PAIR_MAP] \\ rw[]
  >- (
    qmatch_assum_rename_tac`ALOOKUP _ fnm = SOME r` \\
    qexists_tac`if fd = 0 then off else inp` \\ rw[] \\
    metis_tac[SOME_11,PAIR,FST,SND,lemma] ) \\
  qmatch_assum_rename_tac`ALOOKUP _ fnm = SOME r` \\
  qexists_tac`if fd = 0 then MAX (LENGTH r) off else inp` \\ rw[] \\
  metis_tac[SOME_11,PAIR,FST,SND,lemma] );

val get_file_content_add_stdout = Q.store_thm("get_file_content_add_stdout",
  `STD_streams fs ∧ fd ≠ 1 ⇒
   get_file_content (add_stdout fs out) fd = get_file_content fs fd`,
  rw[get_file_content_def,add_stdo_def,up_stdo_def,fsupdate_def]
  \\ CASE_TAC \\ CASE_TAC \\ simp[ALIST_FUPDKEY_ALOOKUP]
  \\ TOP_CASE_TAC \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ CASE_TAC
  >- metis_tac[STD_streams_def,SOME_11,PAIR,FST,SND]
  \\ CASE_TAC);

val linesFD_add_stdout = Q.store_thm("linesFD_add_stdout",
  `STD_streams fs ∧ fd ≠ 1 ⇒
   linesFD (add_stdout fs out) fd = linesFD fs fd`,
  rw[linesFD_def,get_file_content_add_stdout]);

val get_file_content_add_stderr = Q.store_thm("get_file_content_add_stderr",
  `STD_streams fs ∧ fd ≠ 2 ⇒
   get_file_content (add_stderr fs err) fd = get_file_content fs fd`,
  rw[get_file_content_def,add_stdo_def,up_stdo_def,fsupdate_def]
  \\ CASE_TAC \\ CASE_TAC \\ simp[ALIST_FUPDKEY_ALOOKUP]
  \\ TOP_CASE_TAC \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ CASE_TAC
  >- metis_tac[STD_streams_def,SOME_11,PAIR,FST,SND]
  \\ CASE_TAC);

val linesFD_add_stderr = Q.store_thm("linesFD_add_stderr",
  `STD_streams fs ∧ fd ≠ 2 ⇒
   linesFD (add_stderr fs err) fd = linesFD fs fd`,
  rw[linesFD_def,get_file_content_add_stderr]);

val lineFD_NONE_lineForwardFD_fastForwardFD = Q.store_thm("lineFD_NONE_lineForwardFD_fastForwardFD",
  `lineFD fs fd = NONE ⇒
   lineForwardFD fs fd = fastForwardFD fs fd`,
  rw[lineFD_def,lineForwardFD_def,fastForwardFD_def,get_file_content_def]
  \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[libTheory.the_def]
  \\ rveq \\ fs[libTheory.the_def]
  \\ rw[] \\ TRY (
    simp[IO_fs_component_equality]
    \\ match_mp_tac (GSYM ALIST_FUPDKEY_unchanged)
    \\ simp[MAX_DEF] )
  \\ rw[] \\ fs[forwardFD_def,libTheory.the_def]
  \\ pairarg_tac \\ fs[]);

val up_stdo_forwardFD = Q.store_thm("up_stdo_forwardFD",
  `fd ≠ fd' ⇒ up_stdo fd' (forwardFD fs fd n) out = forwardFD (up_stdo fd' fs out) fd n`,
  rw[forwardFD_def,up_stdo_def,fsupdate_def,ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC \\ CASE_TAC \\ rw[]
  \\ match_mp_tac ALIST_FUPDKEY_comm \\ rw[]);

val up_stdout_fastForwardFD = Q.store_thm("up_stdout_fastForwardFD",
  `STD_streams fs ⇒
   up_stdout (fastForwardFD fs fd) out = fastForwardFD (up_stdout fs out) fd`,
  rw[fastForwardFD_def,up_stdo_def]
  \\ Cases_on`ALOOKUP fs.infds fd` >- (
    fs[libTheory.the_def,fsupdate_def]
    \\ CASE_TAC \\ fs[libTheory.the_def]
    \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP] )
  \\ fs[] \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` >- (
    fs[libTheory.the_def,fsupdate_def]
    \\ CASE_TAC \\ fs[libTheory.the_def]
    \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
    \\ rw[libTheory.the_def] )
  \\ fs[libTheory.the_def]
  \\ fs[fsupdate_def,libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  >- ( rw[ALIST_FUPDKEY_o,o_DEF,PAIR_MAP] )
  \\ CASE_TAC \\ fs[libTheory.the_def]
  \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  \\ rw[libTheory.the_def,ALIST_FUPDKEY_comm]
  \\ metis_tac[STD_streams_def,SOME_11,PAIR,FST,SND]);

val up_stderr_fastForwardFD = Q.store_thm("up_stderr_fastForwardFD",
  `STD_streams fs ⇒
   up_stderr (fastForwardFD fs fd) out = fastForwardFD (up_stderr fs out) fd`,
  rw[fastForwardFD_def,up_stdo_def]
  \\ Cases_on`ALOOKUP fs.infds fd` >- (
    fs[libTheory.the_def,fsupdate_def]
    \\ CASE_TAC \\ fs[libTheory.the_def]
    \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP] )
  \\ fs[] \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` >- (
    fs[libTheory.the_def,fsupdate_def]
    \\ CASE_TAC \\ fs[libTheory.the_def]
    \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
    \\ rw[libTheory.the_def] )
  \\ fs[libTheory.the_def]
  \\ fs[fsupdate_def,libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  >- ( rw[ALIST_FUPDKEY_o,o_DEF,PAIR_MAP] )
  \\ CASE_TAC \\ fs[libTheory.the_def]
  \\ CASE_TAC \\ fs[libTheory.the_def,ALIST_FUPDKEY_ALOOKUP]
  \\ rw[libTheory.the_def,ALIST_FUPDKEY_comm]
  \\ metis_tac[STD_streams_def,SOME_11,PAIR,FST,SND]);

val stdo_forwardFD = Q.store_thm("stdo_forwardFD",
  `fd ≠ fd' ⇒ (stdo fd' nm (forwardFD fs fd n) out ⇔ stdo fd' nm fs out)`,
  rw[stdo_def,forwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ CASE_TAC);

val stdo_fastForwardFD = Q.store_thm("stdo_fastForwardFD",
  `fd ≠ fd' ⇒ (stdo fd' nm (fastForwardFD fs fd) out ⇔ stdo fd' nm fs out)`,
  rw[stdo_def,fastForwardFD_def,ALIST_FUPDKEY_ALOOKUP]
  \\ Cases_on`ALOOKUP fs.infds fd` \\ fs[libTheory.the_def]
  \\ pairarg_tac \\ fs[]
  \\ Cases_on`ALOOKUP fs.files fnm` \\ fs[libTheory.the_def]
  \\ fs[ALIST_FUPDKEY_ALOOKUP] \\ rw[]
  \\ CASE_TAC);

val add_stdo_forwardFD = Q.store_thm("add_stdo_forwardFD",
  `fd ≠ fd' ⇒ add_stdo fd' nm (forwardFD fs fd n) out = forwardFD (add_stdo fd' nm fs out) fd n`,
  rw[add_stdo_def,stdo_forwardFD,up_stdo_forwardFD]);

val add_stdout_lineForwardFD = Q.store_thm("add_stdout_lineForwardFD",
  `STD_streams fs ∧ fd ≠ 1 ⇒
   add_stdout (lineForwardFD fs fd) out = lineForwardFD (add_stdout fs out) fd`,
  rw[lineForwardFD_def,get_file_content_add_stdout]
  \\ CASE_TAC \\ CASE_TAC
  \\ rw[] \\ pairarg_tac \\ fs[add_stdo_forwardFD]);

val add_stdout_fastForwardFD = Q.store_thm("add_stdout_fastForwardFD",
  `STD_streams fs ∧ fd ≠ 1 ⇒
   add_stdout (fastForwardFD fs fd) out = fastForwardFD (add_stdout fs out) fd`,
  rw[add_stdo_def,up_stdout_fastForwardFD,stdo_fastForwardFD]);

val add_stderr_lineForwardFD = Q.store_thm("add_stderr_lineForwardFD",
  `STD_streams fs ∧ fd ≠ 2 ⇒
   add_stderr (lineForwardFD fs fd) out = lineForwardFD (add_stderr fs out) fd`,
  rw[lineForwardFD_def,get_file_content_add_stderr]
  \\ CASE_TAC \\ CASE_TAC
  \\ rw[] \\ pairarg_tac \\ fs[add_stdo_forwardFD]);

val add_stderr_fastForwardFD = Q.store_thm("add_stderr_fastForwardFD",
  `STD_streams fs ∧ fd ≠ 2 ⇒
   add_stderr (fastForwardFD fs fd) out = fastForwardFD (add_stderr fs out) fd`,
  rw[add_stdo_def,up_stderr_fastForwardFD,stdo_fastForwardFD]);

val _ = export_theory();
