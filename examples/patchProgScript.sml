open preamble basis
     charsetTheory diffTheory

val _ = new_theory "patchProg";

val _ = translation_extends"basisProg";

fun def_of_const tm = let
  val res = dest_thy_const tm handle HOL_ERR _ =>
              failwith ("Unable to translate: " ^ term_to_string tm)
  val name = (#Name res)
  fun def_from_thy thy name =
    DB.fetch thy (name ^ "_def") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_DEF") handle HOL_ERR _ =>
    DB.fetch thy (name ^ "_thm") handle HOL_ERR _ =>
    DB.fetch thy name
  val def = def_from_thy (#Thy res) name handle HOL_ERR _ =>
            failwith ("Unable to find definition of " ^ name)
  in def end

val _ = find_def_for_const := def_of_const;

val _ = translate parse_patch_header_def;

val tokens_less_eq = Q.prove(`!s f. EVERY (\x. strlen x <= strlen s) (tokens f s)`,
  Induct >> Ho_Rewrite.PURE_ONCE_REWRITE_TAC[SWAP_FORALL_THM]
  >> PURE_ONCE_REWRITE_TAC[TOKENS_eq_tokens_sym]
  >> recInduct TOKENS_ind >> rpt strip_tac
  >> fs[TOKENS_def] >> pairarg_tac >> reverse(Cases_on `l`) >> rw[]
  >- (drule SPLITP_JOIN >> fs[implode_def,strlen_def])
  >> fs[SPLITP_NIL_FST,SPLITP] >> every_case_tac >> fs[]
  >- (`!x. (λx. strlen x <= STRLEN r) x ==> (λx. strlen x <= SUC (STRLEN t)) x`
       by(rpt strip_tac >> PURE_ONCE_REWRITE_TAC[SPLITP_LENGTH] >> fs[])
       >> drule EVERY_MONOTONIC >> pop_assum kall_tac >> disch_then match_mp_tac >> rw[])
  >> `!x. (λx. strlen x <= STRLEN t) x ==> (λx. strlen x <= SUC (STRLEN t)) x` by fs[]
  >> drule EVERY_MONOTONIC >> pop_assum kall_tac >> disch_then match_mp_tac >> rw[]);

val tokens_sum_less_eq = Q.prove(`!s f. SUM(MAP strlen (tokens f s)) <= strlen s`,
  Induct >> Ho_Rewrite.PURE_ONCE_REWRITE_TAC[SWAP_FORALL_THM]
  >> PURE_REWRITE_TAC[TOKENS_eq_tokens_sym,explode_thm,MAP_MAP_o]
  >> recInduct TOKENS_ind >> rpt strip_tac
  >> fs[TOKENS_def] >> pairarg_tac >> fs[] >> Cases_on `l` >> rw[] >> rfs[]
  >> fs[SPLITP_NIL_FST] >> fs[SPLITP] >> every_case_tac
  >> fs[] >> rveq
  >> CONV_TAC(RAND_CONV(ONCE_REWRITE_CONV[SPLITP_LENGTH])) >> fs[]);

val tokens_not_nil = Q.prove(`!s f. EVERY (\x. x <> strlit "") (tokens f s)`,
  Induct >> Ho_Rewrite.PURE_ONCE_REWRITE_TAC[SWAP_FORALL_THM]
  >> PURE_REWRITE_TAC[TOKENS_eq_tokens_sym,explode_thm]
  >> recInduct TOKENS_ind >> rpt strip_tac
  >> rw[TOKENS_def] >> pairarg_tac >> fs[] >> reverse(Cases_on `l`)
  >> fs[implode_def]);

val tokens_two_less = Q.prove(`!s f s1 s2. tokens f s = [s1;s2] ==> strlen s1 < strlen s /\ strlen s2 < strlen s`,
  ntac 2 strip_tac >> qspecl_then [`s`,`f`] assume_tac tokens_sum_less_eq
  >> qspecl_then [`s`,`f`] assume_tac tokens_not_nil
  >> Induct >> Cases >> Induct >> Cases >> rpt strip_tac >> fs[]);

val hexDigit_IMP_digit = Q.store_thm("hexDigit_IMP_digit",`!c. isDigit c ==> isHexDigit c`,
  rw[isHexDigit_def,isDigit_def]);

val parse_patch_header_side = Q.prove(`!s. parse_patch_header_side s = T`,
  rw[fetch "-" "parse_patch_header_side_def"]
  >> TRY(match_mp_tac(MATCH_MP EVERY_MONOTONIC hexDigit_IMP_digit) >> fs[string_is_num_def])
  >> TRY(match_mp_tac hexDigit_IMP_digit >> fs[string_is_num_def])
  >> metis_tac[tokens_two_less]) |> update_precondition;

val r = translate(depatch_line_def);
val depatch_line_side = Q.prove(
  `∀x. depatch_line_side x = T`,
  EVAL_TAC \\ rw[]) |> update_precondition;

val r = save_thm("patch_aux_ind",
  patch_aux_ind |> REWRITE_RULE (map GSYM [mllistTheory.take_def,
                                           mllistTheory.drop_def]));
val _ = add_preferred_thy"-";
val _ = translate(patch_aux_def |> REWRITE_RULE (map GSYM [mllistTheory.take_def,
                                                           mllistTheory.drop_def]));

val _ = translate patch_alg_def;

val notfound_string_def = Define`
  notfound_string f = concat[strlit"cake_patch: ";f;strlit": No such file or directory\n"]`;

val r = translate notfound_string_def;

val usage_string_def = Define`
  usage_string = strlit"Usage: patch <file> <patch>\n"`;

val r = translate usage_string_def;

val rejected_patch_string_def = Define`
  rejected_patch_string = strlit"cake_patch: Patch rejected\n"`;

val r = translate rejected_patch_string_def;

val _ = (append_prog o process_topdecs) `
  fun patch' fname1 fname2 =
    case TextIO.inputLinesFrom fname1 of
        NONE => TextIO.prerr_string (notfound_string fname1)
      | SOME lines1 =>
        case TextIO.inputLinesFrom fname2 of
            NONE => TextIO.prerr_string (notfound_string fname2)
          | SOME lines2 =>
            case patch_alg lines2 lines1 of
                NONE => TextIO.prerr_string (rejected_patch_string)
              | SOME s => TextIO.print_list s`

val patch'_spec = Q.store_thm("patch'_spec",
  `FILENAME f1 fv1 ∧ FILENAME f2 fv2 /\ hasFreeFD fs
   ⇒
   app (p:'ffi ffi_proj) ^(fetch_v"patch'"(get_ml_prog_state()))
     [fv1; fv2]
     (STDIO fs)
     (POSTv uv. &UNIT_TYPE () uv *
       STDIO
       (if inFS_fname fs (File f1) then
        if inFS_fname fs (File f2) then
        case patch_alg (all_lines fs (File f2)) (all_lines fs (File f1)) of
        | NONE => add_stderr fs (explode rejected_patch_string)
        | SOME s => add_stdout fs (CONCAT (MAP explode s))
        else add_stderr fs (explode (notfound_string f2))
        else add_stderr fs (explode (notfound_string f1))))`,
  xcf"patch'"(get_ml_prog_state())
  (* TODO: why doesn't this work fully auto? *)
  \\ xlet_auto_spec(SOME inputLinesFrom_spec) >- xsimpl
  \\ xmatch \\ reverse(Cases_on `inFS_fname fs (File f1)`)
  \\ fs[ml_translatorTheory.OPTION_TYPE_def]
  >- (reverse strip_tac
      >- (strip_tac >> EVAL_TAC)
      \\ xlet_auto >- xsimpl
      \\ xapp \\ xsimpl)
  \\ PURE_REWRITE_TAC [GSYM CONJ_ASSOC] \\ reverse strip_tac
  >- (EVAL_TAC \\ rw[])
  (* TODO: why doesn't this work fully auto? *)
  \\ xlet_auto_spec(SOME inputLinesFrom_spec) >- xsimpl
  \\ xmatch \\ reverse(Cases_on `inFS_fname fs (File f2)`)
  \\ fs[ml_translatorTheory.OPTION_TYPE_def]
  >- (reverse strip_tac
      >- (strip_tac >> EVAL_TAC)
      \\ xlet_auto >- xsimpl
      \\ xapp \\ xsimpl)
  \\ PURE_REWRITE_TAC [GSYM CONJ_ASSOC] \\ reverse strip_tac
  >- (EVAL_TAC \\ rw[])
  \\ xlet_auto >- xsimpl
  \\ qpat_abbrev_tac `a1 = patch_alg _ _`
  \\ Cases_on `a1` \\ fs[ml_translatorTheory.OPTION_TYPE_def]
  \\ xmatch
  >- (xapp \\ ACCEPT_TAC(theorem "rejected_patch_string_v_thm"))
  \\ xapp \\ rw[]);

val _ = (append_prog o process_topdecs) `
  fun patch u =
    case Commandline.arguments () of
        (f1::f2::[]) => patch' f1 f2
      | _ => TextIO.prerr_string usage_string`

val patch_spec = Q.store_thm("patch_spec",
  `hasFreeFD fs
   ⇒
   app (p:'ffi ffi_proj) ^(fetch_v"patch"(get_ml_prog_state()))
     [Conv NONE []]
     (STDIO fs * COMMANDLINE cl)
     (POSTv uv. &UNIT_TYPE () uv *
                STDIO (
                  if (LENGTH cl = 3) then
                  if inFS_fname fs (File (implode (EL 1 cl))) then
                  if inFS_fname fs (File (implode (EL 2 cl))) then
                   case patch_alg (all_lines fs (File (implode (EL 2 cl))))
                                  (all_lines fs (File (implode (EL 1 cl)))) of
                     NONE => add_stderr fs (explode (rejected_patch_string))
                   | SOME s => add_stdout fs (CONCAT (MAP explode s))
                  else add_stderr fs (explode (notfound_string (implode (EL 2 cl))))
                  else add_stderr fs (explode (notfound_string (implode (EL 1 cl))))
                  else add_stderr fs (explode usage_string)) * COMMANDLINE cl)`,
  strip_tac \\ xcf "patch" (get_ml_prog_state())
  \\ xlet_auto >- (xcon \\ xsimpl)
  \\ reverse(Cases_on`wfcl cl`) >- (fs[COMMANDLINE_def] \\ xpull)
  \\ fs[wfcl_def]
  \\ xlet_auto >- xsimpl
  \\ Cases_on `cl` \\ fs[]
  \\ Cases_on `t` \\ fs[ml_translatorTheory.LIST_TYPE_def]
  >- (xmatch \\ xapp \\ xsimpl \\ CONV_TAC SWAP_EXISTS_CONV
      \\ qexists_tac `usage_string` \\ simp [theorem "usage_string_v_thm"]
      \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `fs` \\ xsimpl)
  \\ Cases_on `t'` \\ fs[ml_translatorTheory.LIST_TYPE_def]
  >- (xmatch \\ xapp \\ xsimpl \\ CONV_TAC SWAP_EXISTS_CONV
      \\ qexists_tac `usage_string` \\ simp [theorem "usage_string_v_thm"]
      \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `fs` \\ xsimpl)
  \\ xmatch
  \\ reverse(Cases_on `t`) \\ fs[ml_translatorTheory.LIST_TYPE_def]
  \\ PURE_REWRITE_TAC [GSYM CONJ_ASSOC] \\ (reverse strip_tac >- (EVAL_TAC \\ rw[]))
  >- (xapp \\ xsimpl \\ CONV_TAC SWAP_EXISTS_CONV
      \\ qexists_tac `usage_string` \\ simp [theorem "usage_string_v_thm"]
      \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `fs` \\ xsimpl)
  \\ xapp
  \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `fs`
  \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `implode h''`
  \\ CONV_TAC SWAP_EXISTS_CONV \\ qexists_tac `implode h'`
  \\ xsimpl \\ fs[FILENAME_def]
  \\ fs[validArg_def,EVERY_MEM]);

val st = get_ml_prog_state();

val name = "patch"
val spec = patch_spec |> UNDISCH |> SIMP_RULE(srw_ss())[STDIO_def]
           |> add_basis_proj
val (sem_thm,prog_tm) = call_thm st name spec

val patch_prog_def = Define`patch_prog = ^prog_tm`;

val patch_semantics = save_thm("patch_semantics",
  sem_thm
  |> REWRITE_RULE[GSYM patch_prog_def]
  |> DISCH_ALL
  |> CONV_RULE(LAND_CONV EVAL)
  |> REWRITE_RULE[AND_IMP_INTRO,GSYM CONJ_ASSOC]
  |> SIMP_RULE(srw_ss())[Once option_case_compute]
  |> SIMP_RULE(srw_ss())[STD_streams_add_stdout,STD_streams_add_stderr,
                         Q.ISPEC`STD_streams`COND_RAND]);

val _ = export_theory ();
