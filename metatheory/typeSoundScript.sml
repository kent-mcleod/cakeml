open preamble MiniMLTheory MiniMLTerminationTheory typeSystemTheory;

val _ = new_theory "typeSound";

val context_invariant_determ = Q.prove (
`!dec_tvs c tvs1. context_invariant dec_tvs c tvs1 ⇒ 
    ∀ tvs2. 
      context_invariant dec_tvs c tvs2 ⇒ 
      (tvs1 = tvs2)`,
ho_match_mp_tac context_invariant_ind >>
rw [] >>
pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >>
fs []);

val type_v_freevars = Q.prove (
`(!tvs cenv senv v t. type_v tvs cenv senv v t ⇒
   check_freevars tvs [] t) ∧
 (!tvs cenv senv vs ts. type_vs tvs cenv senv vs ts ⇒
   EVERY (check_freevars tvs []) ts) ∧
 (!cenv senv env tenv. type_env cenv senv env tenv ⇒
   tenv_ok tenv ∧ (num_tvs tenv = 0))`,
ho_match_mp_tac type_v_strongind >>
rw [check_freevars_def, tenv_ok_def, bind_tenv_def, num_tvs_def, bind_tvar_def] >-
metis_tac [] >>
res_tac >|
[metis_tac [num_tvs_def, type_e_freevars, bind_tenv_def, bind_tvar_def,
            tenv_ok_def, arithmeticTheory.ADD, arithmeticTheory.ADD_COMM],
 metis_tac [num_tvs_def, type_e_freevars, bind_tenv_def, bind_tvar_def,
            tenv_ok_def, arithmeticTheory.ADD, arithmeticTheory.ADD_COMM],
 metis_tac [type_funs_Tfn, num_tvs_bind_var_list],
 metis_tac [type_funs_Tfn, num_tvs_bind_var_list, num_tvs_def,
            arithmeticTheory.ADD, arithmeticTheory.ADD_COMM],
 metis_tac [check_freevars_add, arithmeticTheory.ZERO_LESS_EQ,
                arithmeticTheory.GREATER_EQ]]);

val type_ctxts_freevars = Q.prove (
`!dec_tvs cenv senv cs t1 t2.
  type_ctxts dec_tvs cenv senv cs t1 t2
  ⇒ 
  !tvs. tenvC_ok cenv ∧ context_invariant dec_tvs cs tvs ⇒
  check_freevars tvs [] t1 ∧ check_freevars dec_tvs [] t2`,
ho_match_mp_tac type_ctxts_ind >>
rw [type_ctxt_cases, check_freevars_def] >>
imp_res_tac context_invariant_determ >>
rw [] >>
pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >|
[metis_tac [],
 metis_tac [],
 metis_tac [check_freevars_add, arithmeticTheory.ZERO_LESS_EQ,
                arithmeticTheory.GREATER_EQ],
 fs [type_uop_def] >>
     cases_on `uop` >>
     fs [] >-
     metis_tac [check_freevars_def] >>
     cases_on `t1` >>
     fs [] >>
     rw [] >>
     metis_tac [check_freevars_def],
 fs [type_op_def] >>
     cases_on `op` >>
     fs [] >|
     [cases_on `t1` >>
          fs [] >>
          cases_on `t2'` >>
          fs [check_freevars_def] >>
          metis_tac [],
      cases_on `t1` >>
          fs [] >>
          cases_on `t2'` >>
          fs [check_freevars_def] >>
          metis_tac [],
      metis_tac [type_e_freevars, type_v_freevars],
      cases_on `t1` >>
          fs [check_freevars_def] >>
          metis_tac [type_e_freevars, type_v_freevars],
      cases_on `t1` >>
          fs [check_freevars_def] >>
          metis_tac [type_e_freevars, type_v_freevars]],
 fs [type_op_def] >>
     cases_on `op` >>
     fs [] >|
     [cases_on `t1''` >>
          fs [] >>
          cases_on `t1` >>
          fs [check_freevars_def] >>
          metis_tac [],
      cases_on `t1''` >>
          fs [] >>
          cases_on `t1` >>
          fs [check_freevars_def] >>
          metis_tac [],
      metis_tac [type_e_freevars, type_v_freevars],
      cases_on `t1''` >>
          fs [check_freevars_def] >>
          metis_tac [type_e_freevars, type_v_freevars, check_freevars_def],
      cases_on `t1''` >>
          fs [check_freevars_def] >>
          metis_tac [type_e_freevars, type_v_freevars, check_freevars_def]],
 rw [check_freevars_def],
 metis_tac [],
 rw [check_freevars_def],
 metis_tac [],
 cases_on `pes` >>
     fs [RES_FORALL] >>
     qpat_assum `!x. (x = h) ∨ MEM x t ⇒ P x` (ASSUME_TAC o Q.SPEC `h`) >>
     fs [] >>
     PairCases_on `h` >>
     fs [] >>
     fs [Once context_invariant_cases] >>
     metis_tac [type_p_freevars],
 metis_tac [],
 metis_tac [],
 imp_res_tac tenvC_ok_lookup >>
     fs [] >>
     match_mp_tac check_freevars_subst_single >>
     rw [] >>
     metis_tac [check_freevars_add, arithmeticTheory.ZERO_LESS_EQ,
                arithmeticTheory.GREATER_EQ],
 metis_tac []]);     

(* Everything in the type environment is also in the execution environment *)
val type_lookup_lem = Q.prove (
`∀tenvC env tenvs tenv v s t' idx.
  type_env tenvC tenvs env tenv ∧
  (lookup_tenv s idx tenv = SOME t')
  ⇒
  (∃v'. lookup s env = SOME v')`,
induct_on `tenv` >>
rw [Once type_v_cases, lookup_def, bind_def] >>
fs [lookup_tenv_def, bind_tenv_def] >-
metis_tac [] >>
every_case_tac >>
fs [] >>
metis_tac []);

val type_lookup = Q.prove (
`∀tenvC env tenvs tenv v s t' idx tvs.
  type_env tenvC tenvs env tenv ∧
  (lookup_tenv s idx (bind_tvar tvs tenv) = SOME t')
  ⇒
  (∃v'. lookup s env = SOME v')`,
induct_on `tvs` >>
rw [bind_tvar_def] >-
metis_tac [type_lookup_lem] >>
fs [bind_tvar_def, lookup_tenv_def] >>
rw [] >>
every_case_tac >>
fs [lookup_tenv_def] >>
`!x y. x + SUC y = (x + 1) + y` by decide_tac >>
metis_tac []);

val type_vs_length_lem = Q.prove (
`∀tvs tenvC tenvs vs ts.
  type_vs tvs tenvC tenvs vs ts ⇒ (LENGTH vs = LENGTH ts)`,
induct_on `vs` >>
rw [Once type_v_cases] >>
rw [] >>
metis_tac []);

(* Typing lists of values from the end *)
val type_vs_end_lem = Q.prove (
`∀tvs tenvC vs ts v t tenvs.
  type_vs tvs tenvC tenvs (vs++[v]) (ts++[t]) =
  type_v tvs tenvC tenvs v t ∧
  type_vs tvs tenvC tenvs vs ts`,
induct_on `vs` >>
rw [] >>
cases_on `ts` >>
fs [] >>
EQ_TAC >>
rw [] >|
[pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [],
 pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [],
 metis_tac [type_v_rules],
 imp_res_tac type_vs_length_lem >>
     fs [],
 imp_res_tac type_vs_length_lem >>
     fs [],
 imp_res_tac type_vs_length_lem >>
     fs [],
 imp_res_tac type_vs_length_lem >>
     fs [],
 imp_res_tac type_vs_length_lem >>
     fs [],
 imp_res_tac type_vs_length_lem >>
     fs [],
 pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [] >>
     metis_tac [],
 pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [] >>
     metis_tac [type_v_rules],
 rw [Once type_v_cases] >>
     pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs []]);

(* Classifying values of basic types *)
val canonical_values_thm = Q.prove (
`∀tvs tenvC tenvs v t1 t2.
  (type_v tvs tenvC tenvs v (Tref t1) ⇒ (∃n. v = Loc n)) ∧
  (type_v tvs tenvC tenvs v Tint ⇒ (∃n. v = Litv (IntLit n))) ∧
  (type_v tvs tenvC tenvs v Tbool ⇒ (∃n. v = Litv (Bool n))) ∧
  (type_v tvs tenvC tenvs v Tunit ⇒ (∃n. v = Litv Unit)) ∧
  (type_v tvs tenvC tenvs v (Tfn t1 t2) ⇒
    (∃env n topt e. v = Closure env n topt e) ∨
    (∃env funs n. v = Recclosure env funs n))`,
rw [] >>
fs [Once type_v_cases, deBruijn_subst_def] >>
rw [] >>
metis_tac [type_funs_Tfn, t_distinct]);

(* Well-typed pattern matches either match or not, but they don't raise type
 * errors *)
val pmatch_type_progress = Q.prove (
`(∀tvs' envC s p v env t tenv tenvs tvs.
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  type_p tvs'' tenvC p t tenv ∧
  type_v tvs tenvC tenvs v t ∧
  type_s tenvC tenvs s
  ⇒
  (pmatch tvs' envC s p v env = No_match) ∨
  (∃env'. pmatch tvs' envC s p v env = Match env')) ∧
 (∀tvs' envC s ps vs env ts tenv tenvs tvs.
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  type_ps tvs'' tenvC ps ts tenv ∧
  type_vs tvs tenvC tenvs vs ts ∧
  type_s tenvC tenvs s
  ⇒
  (pmatch_list tvs' envC s ps vs env = No_match) ∨
  (∃env'. pmatch_list tvs' envC s ps vs env = Match env'))`,
ho_match_mp_tac pmatch_ind >>
rw [] >>
rw [pmatch_def] >>
fs [lit_same_type_def] >|
[fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [],
 fs [Once (hd (CONJUNCTS type_v_cases)),
     Once (hd (CONJUNCTS type_p_cases))] >>
     rw [] >>
     fs [] >>
     imp_res_tac consistent_con_env_thm >>
     rw [] >>
     metis_tac [type_ps_length, type_vs_length_lem, LENGTH_MAP],
 fs [Once type_p_cases, Once type_v_cases, consistent_con_env2_def] >>
     imp_res_tac consistent_con_env_thm >>
     rw [] >>
     res_tac >>
     fs [] >>
     rw [] >>
     metis_tac [type_ps_length, type_vs_length_lem, LENGTH_MAP],
 qpat_assum `type_v a b c d e` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     qpat_assum `type_p a0 a b c d` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     every_case_tac >>
     rw [] >>
     fs [type_s_def] >>
     res_tac >>
     fs [] >>
     rw [] >>
     metis_tac [],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 fs [Once type_v_cases, Once type_p_cases, lit_same_type_def] >>
     rw [] >>
     fs [deBruijn_subst_def] >>
     metis_tac [type_funs_Tfn, t_distinct],
 qpat_assum `type_ps tvs tenvC (p::ps) ts tenv`
         (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     qpat_assum `type_vs tvs tenvC tenvs (v::vs) ts`
         (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     metis_tac [],
 imp_res_tac type_ps_length >>
     imp_res_tac type_vs_length_lem >>
     fs [] >>
     cases_on `ts` >>
     fs [],
 imp_res_tac type_ps_length >>
     imp_res_tac type_vs_length_lem >>
     fs [] >>
     cases_on `ts` >>
     fs []]);

val final_state_def = Define `
  (final_state (tenvC,s,env,Val v,[]) = T) ∧
  (final_state (tenvC,s,env,Exp (Raise err),[]) = T) ∧
  (final_state _ = F)`;

val not_final_state = Q.prove (
`!tenvC s env e c.
  ¬final_state (tenvC,s,env,Exp e,c) =
     (?x y. c = x::y) ∨
     (?e1 x e2. e = Handle e1 x e2) ∨
     (?l. e = Lit l) ∨
     (?cn es. e = Con cn es) ∨
     (?v targ. e = Var v targ) ∨
     (?x topt e'. e = Fun x topt e') \/
     (?op e1 e2. e = App op e1 e2) ∨
     (?uop e1. e = Uapp uop e1) ∨
     (?op e1 e2. e = Log op e1 e2) ∨
     (?e1 e2 e3. e = If e1 e2 e3) ∨
     (?e' pes. e = Mat e' pes) ∨
     (?tvs n topt e1 e2. e = Let tvs n topt e1 e2) ∨
     (?tvs funs e'. e = Letrec tvs funs e')`,
rw [] >>
cases_on `e` >>
cases_on `c` >>
rw [final_state_def]);

(* A well-typed expression state is either a value with no continuation, or it
* can step to another state, or it steps to a BindError. *)
val exp_type_progress = Q.prove (
`∀dec_tvs tenvC s tenv e t envC env c tvs.
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  type_state dec_tvs tenvC (envC, s, env, e, c) t ∧
  ¬(final_state (envC, s, env, e, c))
  ⇒
  (∃env' s' e' c'. e_step (envC, s, env, e, c) = Estep (envC, s', env', e', c'))`,
rw [] >>
rw [e_step_def] >>
fs [type_state_cases, push_def, return_def] >>
rw [] >|
[fs [Once type_e_cases] >>
     rw [] >>
     fs [not_final_state] >|
     [imp_res_tac consistent_con_env_thm >>
          rw [] >>
          every_case_tac >>
          fs [return_def] >>
          imp_res_tac type_es_length >>
          fs [],
      fs [do_con_check_def] >>
          rw [] >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          rw [] >>
          every_case_tac >>
          fs [return_def] >>
          imp_res_tac type_es_length >>
          fs [],
      fs [do_con_check_def] >>
          rw [] >>
          fs [] >>
          imp_res_tac consistent_con_env_thm >>
          rw [] >>
          every_case_tac >>
          fs [return_def] >>
          imp_res_tac type_es_length >>
          fs [],
      imp_res_tac type_lookup >>
          fs [] >>
          rw [] >>
          PairCases_on `v'` >>
          rw [],
      metis_tac [type_funs_distinct]],
 rw [continue_def] >>
     fs [Once type_ctxts_cases, type_ctxt_cases, return_def, push_def] >>
     rw [] >>
     fs [final_state_def] >>
     fs [] >>
     fs [type_op_cases] >>
     rw [] >>
     imp_res_tac canonical_values_thm >>
     fs [] >>
     rw [] >>
     fs [do_app_def, do_if_def, do_log_def] >|
     [rw [do_uapp_def] >>
          every_case_tac >>
          rw [store_alloc_def] >>
          fs [Once type_v_cases] >>
          rw [] >>
          fs [type_uop_def] >>
          every_case_tac >>
          fs [type_s_def] >>
          rw [] >>
          imp_res_tac type_funs_Tfn >>
          fs [] >>
          metis_tac [optionTheory.NOT_SOME_NONE],
      every_case_tac >>
          fs [],
      every_case_tac >>
          fs [] >>
          qpat_assum `type_v a tenvC senv (Recclosure x2 x3 x4) tpat`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
          fs [] >>
          imp_res_tac type_funs_find_recfun >>
          fs [],
      qpat_assum `type_v a tenvC senv (Loc n) z` 
                  (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
          fs [type_s_def] >>
          res_tac >>
          fs [store_assign_def, store_lookup_def],
      every_case_tac >>
          fs [],
      every_case_tac >>
          fs [],
      every_case_tac >>
          fs [RES_FORALL] >>
          rw [] >>
          qpat_assum `∀x. (x = (q,r)) ∨ P x ⇒ Q x`
                   (MP_TAC o Q.SPEC `(q,r)`) >>
          rw [] >>
          CCONTR_TAC >>
          fs [] >>
          `(pmatch (SOME 0) envC s q v env' = No_match) ∨
           (∃env. pmatch (SOME 0) envC s q v env' = Match env)` by
                      metis_tac [pmatch_type_progress] >>
          fs [],
      every_case_tac >>
         fs [] >>
         imp_res_tac consistent_con_env_thm >>
         imp_res_tac type_es_length >>
         imp_res_tac type_vs_length_lem >>
         full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def],
      every_case_tac >>
         fs [] >>
         imp_res_tac consistent_con_env_thm >>
         imp_res_tac type_es_length >>
         imp_res_tac type_vs_length_lem >>
         full_simp_tac (srw_ss()++ARITH_ss) [do_con_check_def]]]);

val pmatch_type_preservation = Q.prove (
`(∀tvs envC s p v env env' (tenvC:tenvC) tenv t tenv' senv.
  (pmatch tvs envC s p v env = Match env') ∧
  (tvs = SOME 0) ∧
  type_v 0 tenvC senv v t ∧
  type_p 0 tenvC p t tenv' ∧
  type_s tenvC senv s ∧
  type_env tenvC senv env tenv ⇒
  type_env tenvC senv env' (bind_var_list 0 tenv' tenv)) ∧
 (∀tvs envC s ps vs env env' (tenvC:tenvC) tenv tenv' ts senv.
  (pmatch_list tvs envC s ps vs env = Match env') ∧
  (tvs = SOME 0) ∧
  type_vs 0 tenvC senv vs ts ∧
  type_ps 0 tenvC ps ts tenv' ∧
  type_s tenvC senv s ∧
  type_env tenvC senv env tenv ⇒
  type_env tenvC senv env' (bind_var_list 0 tenv' tenv))`,
ho_match_mp_tac pmatch_ind >>
rw [pmatch_def] >|
[fs [Once type_p_cases, bind_var_list_def, bind_def] >>
     rw [] >>
     rw [Once type_v_cases] >>
     rw [add_tvs_def, emp_def, bind_def, bind_tenv_def],
 fs [Once type_p_cases, bind_var_list_def],
 every_case_tac >>
     fs [] >>
     qpat_assum `type_v tvs tenvC senv vpat t`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [Once type_p_cases] >>
     rw [] >>
     fs [] >>
     rw [] >>
     cases_on `ps` >>
     fs [] >>
     qpat_assum `type_ps a0 a c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     metis_tac [],
 every_case_tac >>
     fs [],
 fs [store_lookup_def] >>
     every_case_tac >>
     fs [] >>
     qpat_assum `type_p x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     qpat_assum `type_v x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [] >>
     rw [] >>
     fs [type_s_def, store_lookup_def] >>
     metis_tac [],
 fs [Once type_p_cases, bind_var_list_def],
 every_case_tac >>
     fs [] >>
     qpat_assum `type_vs tva tenvC senv (v::vs) ts`
             (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [] >>
     qpat_assum `type_ps a0 a c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     rw [bind_var_list_append] >>
     metis_tac []]);

val type_v_tvs_weaken = Q.prove (
`(!tvs tenvC senv v t. type_v tvs tenvC senv v t ⇒
    !tvs'. (tvs = 0) ⇒ type_v tvs' tenvC senv v t) ∧
 (!tvs tenvC senv vs ts. type_vs tvs tenvC senv vs ts ⇒
    !tvs'. (tvs = 0) ⇒ type_vs tvs' tenvC senv vs ts) ∧
 (!tenvC senv env tenv. type_env tenvC senv env tenv ⇒  
   type_env tenvC senv env tenv)`,
cheat);

(*
ho_match_mp_tac type_v_strongind >>
rw [] >>
rw [Once type_v_cases] >>
metis_tac []
*)

(* A successful pattern match gives a binding environment with the type given by
* the pattern type checker *)
val pmatch_type_preservation = Q.prove (
`(∀tvs envC s p v env env' (tenvC:tenvC) tenv t tenv' senv tvs'.
  (pmatch tvs envC s p v env = Match env') ∧
  (tvs = SOME tvs') ∧
  type_v tvs' tenvC senv v t ∧
  type_p tvs' tenvC p t tenv' ∧
  type_s tenvC senv s ∧
  type_env tenvC senv env tenv ⇒
  type_env tenvC senv env' (bind_var_list tvs' tenv' tenv)) ∧
 (∀tvs envC s ps vs env env' (tenvC:tenvC) tenv tenv' ts senv tvs'.
  (pmatch_list tvs envC s ps vs env = Match env') ∧
  (tvs = SOME tvs') ∧
  type_vs tvs' tenvC senv vs ts ∧
  type_ps tvs' tenvC ps ts tenv' ∧
  type_s tenvC senv s ∧
  type_env tenvC senv env tenv ⇒
  type_env tenvC senv env' (bind_var_list tvs' tenv' tenv))`,
ho_match_mp_tac pmatch_ind >>
rw [pmatch_def] >|
[fs [Once type_p_cases, bind_var_list_def, bind_def] >>
     rw [] >>
     rw [Once type_v_cases] >>
     rw [add_tvs_def, emp_def, bind_def, bind_tenv_def],
 fs [Once type_p_cases, bind_var_list_def],
 every_case_tac >>
     fs [] >>
     qpat_assum `type_v tvs tenvC senv vpat t`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [Once type_p_cases] >>
     rw [] >>
     fs [] >>
     rw [] >>
     cases_on `ps` >>
     fs [] >>
     qpat_assum `type_ps a0 a c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     metis_tac [],
 every_case_tac >>
     fs [],
 fs [store_lookup_def] >>
     every_case_tac >>
     fs [] >>
     qpat_assum `type_p x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     qpat_assum `type_v x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
     fs [] >>
     rw [] >>
     fs [type_s_def, store_lookup_def] >>
     metis_tac [type_v_tvs_weaken],
 fs [Once type_p_cases, bind_var_list_def],
 every_case_tac >>
     fs [] >>
     qpat_assum `type_vs tva tenvC senv (v::vs) ts`
             (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_v_cases]) >>
     fs [] >>
     qpat_assum `type_ps a0 a c d e`
             (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_p_cases]) >>
     fs [] >>
     rw [bind_var_list_append] >>
     metis_tac []]);

val type_env2_def = Define `
(type_env2 tenvC tenvS tvs [] [] = T) ∧
(type_env2 tenvC tenvS tvs ((x,(v,SOME (tvs',t')))::env) ((x',t) ::tenv) = 
  check_freevars tvs [] t ∧ (x = x') ∧ (t = t') ∧ (tvs = tvs') ∧ type_v tvs tenvC tenvS v t ∧ type_env2 tenvC tenvS tvs env tenv) ∧
(type_env2 tenvC tenvS tvs _ _ = F)`;

val type_env_merge_lem1 = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvs.
  type_env2 tenvC tenvs tvs env' tenv' ∧ type_env tenvC tenvs env tenv
  ⇒
  type_env tenvC tenvs (merge env' env) (bind_var_list tvs tenv' tenv) ∧ (LENGTH env' = LENGTH tenv')`,
Induct_on `tenv'` >>
rw [merge_def] >>
cases_on `env'` >>
rw [bind_var_list_def] >>
fs [type_env2_def] >|
[PairCases_on `h` >>
     fs [] >>
     cases_on `h2` >>
     fs [type_env2_def] >>
     PairCases_on `x` >>
     fs [type_env2_def],
 PairCases_on `h` >>
     fs [] >>
     cases_on `h2` >>
     fs [type_env2_def] >>
     PairCases_on `x` >>
     fs [type_env2_def],
 PairCases_on `h` >>
     rw [bind_var_list_def] >>
     PairCases_on `h'` >>
     fs [] >>
     cases_on `h'2` >>
     fs [type_env2_def] >>
     PairCases_on `x` >>
     fs [type_env2_def] >>
     rw [] >>
     rw [Once type_v_cases, bind_def, emp_def, bind_tenv_def] >>
     metis_tac [merge_def],
 PairCases_on `h` >>
     rw [bind_var_list_def] >>
     PairCases_on `h'` >>
     fs [] >>
     cases_on `h'2` >>
     fs [type_env2_def] >>
     PairCases_on `x` >>
     fs [type_env2_def] >>
     rw [] >>
     rw [Once type_v_cases, bind_def, emp_def, bind_tenv_def] >>
     metis_tac [merge_def]]);

val type_env_merge_lem2 = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvs.
  type_env tenvC tenvs (merge env' env) (bind_var_list tvs tenv' tenv) ∧
  (LENGTH env' = LENGTH tenv')
  ⇒
  type_env2 tenvC tenvs tvs env' tenv' ∧ type_env tenvC tenvs env tenv`,
Induct_on `env'` >>
rw [merge_def] >>
cases_on `tenv'` >>
fs [bind_var_list_def] >>
rw [type_env2_def] >>
qpat_assum `type_env x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
PairCases_on `h` >>
PairCases_on `h'` >>
Cases_on `h2` >>
rw [type_env2_def] >>
fs [emp_def, bind_def, bind_var_list_def, bind_tenv_def, merge_def] >>
rw [type_env2_def] >>
metis_tac [type_v_freevars]);

val type_env_merge = Q.prove (
`∀tenvC env env' tenv tenv' tvs tenvs.
  type_env tenvC tenvs (merge env' env) (bind_var_list tvs tenv' tenv) ∧
  (LENGTH env' = LENGTH tenv')
  =
  type_env2 tenvC tenvs tvs env' tenv' ∧ type_env tenvC tenvs env tenv`,
metis_tac [type_env_merge_lem1, type_env_merge_lem2]);

val type_recfun_env_help = Q.prove (
`∀fn funs funs' tenvC tenv tenv' tenv0 env tenvS tvs.
  (!fn t. (lookup fn tenv = SOME t) ⇒ (lookup fn tenv' = SOME t)) ∧
  type_env tenvC tenvS env tenv0 ∧
  type_funs tenvC (bind_var_list 0 tenv' (bind_tvar tvs tenv0)) funs' tenv' ∧
  type_funs tenvC (bind_var_list 0 tenv' (bind_tvar tvs tenv0)) funs tenv
  ⇒
  type_env2 tenvC tenvS tvs (MAP (λ(fn,n,e). (fn,Recclosure env funs' fn, add_tvs (SOME tvs) n)) funs) tenv`,
induct_on `funs` >>
rw [] >>
pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss ()) [Once type_e_cases]) >>
fs [emp_def] >>
rw [bind_def, Once type_v_cases, type_env2_def] >>
`type_env2 tenvC tenvS tvs (MAP (λ(fn,n,e). (fn,Recclosure env funs' fn, add_tvs (SOME tvs) n)) funs) env'`
              by metis_tac [optionTheory.NOT_SOME_NONE, lookup_def, bind_def] >>
rw [type_env2_def, add_tvs_def] >>
fs [add_tvs_def] >>
rw [Once type_v_cases, check_freevars_def] >>
`lookup fn tenv' = SOME (Tfn t1 t2)` by metis_tac [lookup_def, bind_def] >|
[fs [num_tvs_bind_var_list, check_freevars_def] >>
     metis_tac [num_tvs_def, bind_tvar_def, arithmeticTheory.ADD, 
                arithmeticTheory.ADD_COMM, type_v_freevars],
 fs [num_tvs_bind_var_list, check_freevars_def] >>
     metis_tac [num_tvs_def, bind_tvar_def, arithmeticTheory.ADD, 
                arithmeticTheory.ADD_COMM, type_v_freevars],
 qexists_tac `tenv0` >>
     rw [] >>
     qexists_tac `tenv'` >>
     rw []]);

val type_recfun_env = Q.prove (
`∀fn funs tenvC senv tvs tenv tenv0 env.
  type_env tenvC senv env tenv0 ∧
  type_funs tenvC (bind_var_list 0 tenv (bind_tvar tvs tenv0)) funs tenv
  ⇒
  type_env2 tenvC senv tvs (MAP (λ(fn,n,e). (fn,Recclosure env funs fn, add_tvs (SOME tvs) n)) funs) tenv`,
metis_tac [type_recfun_env_help]);

val type_subst_lem1 = 
(GEN_ALL o
 SIMP_RULE (srw_ss()++ARITH_ss) [] o
 Q.SPECL [`[]`, `t`, `0`, `targs`, `tvs`] o
 SIMP_RULE (srw_ss()) [GSYM RIGHT_FORALL_IMP_THM])
check_freevars_subst_inc

val type_subst_lem3 = Q.prove (
`!skip targs t tvs.
  (skip = 0) ∧
  EVERY (check_freevars tvs []) targs ∧
  check_freevars (LENGTH targs) [] t 
  ⇒
  check_freevars tvs [] (deBruijn_subst skip targs t)`,
ho_match_mp_tac deBruijn_subst_ind >>
rw [check_freevars_def, deBruijn_subst_def, EVERY_MAP] >>
fs [EVERY_MEM, MEM_EL] >>
metis_tac []);

val type_e_subst_lem = Q.prove (
`(∀tenvC tenvE e t targs tvs targs'.
  type_e tenvC (bind_tenv x 0 t1 (bind_tvar (LENGTH targs) tenvE)) e t ∧
  (num_tvs tenvE = 0) ∧ 
  tenvC_ok tenvC ∧ 
  tenv_ok (bind_tvar (LENGTH targs) tenvE) ∧
  EVERY (check_freevars tvs []) targs ∧
  check_freevars (LENGTH targs) [] t1
  ⇒
  type_e tenvC (bind_tenv x 0 (deBruijn_subst 0 targs t1) (bind_tvar tvs tenvE)) (deBruijn_subst_e 0 targs e) (deBruijn_subst 0 targs t))`,
rw [bind_tenv_def] >>
match_mp_tac ((SIMP_RULE (srw_ss()) [bind_tenv_def, num_tvs_def, deBruijn_subst_tenvE_def, db_merge_def, deBruijn_inc0] o
               Q.SPECL [`tenvC`, `e`, `t`, `bind_tenv x 0 t1 Empty`] o
               SIMP_RULE (srw_ss()) [GSYM RIGHT_FORALL_IMP_THM, AND_IMP_INTRO] o
               hd o
               CONJUNCTS)
              type_e_subst) >>
rw [tenv_ok_def, bind_tvar_def, num_tvs_def] >>
metis_tac []);

val type_funs_subst_lem = 
(Q.GEN `tenvE2` o
 SIMP_RULE (srw_ss()) [bind_tenv_def, num_tvs_def, deBruijn_subst_tenvE_def,
                       db_merge_def, deBruijn_inc0, num_tvs_bind_var_list,
                       db_merge_bind_var_list, option_map_def,
                       deBruijn_subst_E_bind_var_list] o
 Q.SPECL [`tenvC`, `e`, `t`, `bind_var_list 0 tenv' Empty`] o
 SIMP_RULE (srw_ss()) [GSYM RIGHT_FORALL_IMP_THM, AND_IMP_INTRO] o
 hd o
 tl o
 tl o
 CONJUNCTS)
type_e_subst;

val type_subst = Q.prove (
`(!tvs tenvC senv v t. type_v tvs tenvC senv v t ⇒
    ∀targs tvs'.
      (tvs = LENGTH targs) ∧
      tenvC_ok tenvC ∧
      EVERY (check_freevars tvs' []) targs ∧
      check_freevars (LENGTH targs) [] t
      ⇒
      type_v tvs' tenvC senv (deBruijn_subst_v targs v)
             (deBruijn_subst 0 targs (deBruijn_inc (LENGTH targs) tvs' t))) ∧
(!tvs tenvC senv vs ts. type_vs tvs tenvC senv vs ts ⇒
   ∀targs tvs'.
     (tvs = LENGTH targs) ∧
     tenvC_ok tenvC ∧
     EVERY (check_freevars tvs' []) targs ∧
     EVERY (check_freevars (LENGTH targs) []) ts
     ⇒
     type_vs tvs' tenvC senv (MAP (deBruijn_subst_v targs) vs)
             (MAP (deBruijn_subst 0 targs) (MAP (deBruijn_inc (LENGTH targs) tvs') ts))) ∧
(!tenvC senv env tenv. type_env tenvC senv env tenv ⇒ 
    type_env tenvC senv env tenv)`,
ho_match_mp_tac type_v_strongind >>
rw [deBruijn_subst_v_def] >>
rw [Once type_v_cases] >>
pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
rw [deBruijn_inc_def, deBruijn_subst_def, option_map_def] >>
rw [deBruijn_inc_def, deBruijn_subst_def, option_map_def] >>
fs [check_freevars_def] >>
rw [nil_deBruijn_inc, deBruijn_subst_check_freevars, type_subst_lem3,
    nil_deBruijn_subst] >|
[rw [EVERY_MAP] >>
     fs [EVERY_MEM] >>
     rw [] >>
     metis_tac [type_subst_lem1, EVERY_MEM],
 `EVERY (check_freevars 0 tvs') ts` by metis_tac [tenvC_ok_lookup, EVERY_MEM] >>
     `EVERY (check_freevars (LENGTH targs) tvs') ts`
           by (`LENGTH targs ≥ 0` by decide_tac >>
               metis_tac [EVERY_MEM, check_freevars_add]) >>
     `type_vs tvs'' tenvC senv (MAP (deBruijn_subst_v targs) vs)
              (MAP (deBruijn_subst 0 targs)
                 (MAP (deBruijn_inc (LENGTH targs) tvs'')
                    (MAP (type_subst (ZIP (tvs',ts'))) ts)))`
            by metis_tac [check_freevars_subst_list] >>
     pop_assum mp_tac >>
     rw [type_subst_deBruijn_subst_list, type_subst_deBruijn_inc_list] >>
     metis_tac [],
 qexists_tac `tenv` >>
     rw [] >>
     match_mp_tac type_e_subst_lem >>
     rw [tenv_ok_def, bind_tvar_def] >>
     metis_tac [type_v_freevars],
 qexists_tac `tenv` >>
     qexists_tac `MAP (λ(x,t). (x,deBruijn_subst 0 targs t)) tenv'` >>
     rw [] >|
     [match_mp_tac type_funs_subst_lem >>
          rw [] >-
          metis_tac [type_v_freevars] >>
          match_mp_tac tenv_ok_bind_var_list >>
          metis_tac [tenv_ok_bind_var_list, type_v_freevars, bind_tvar_rewrites],
      qpat_assum `type_funs w x y z` (fn x => ALL_TAC) >>
          induct_on `tenv'` >>
          fs [lookup_def] >>
          rw [] >>
          PairCases_on `h` >>
          fs [] >>
          rw [] >>
          metis_tac []],
 fs [bind_def, bind_tenv_def] >>
     metis_tac [type_v_rules],
 fs [bind_def, bind_tenv_def] >>
     rw [Once type_v_cases] >>
     rw [bind_def, bind_tenv_def]]);

(* They value of a binding in the execution environment has the type given by
 * the type environment. *)
val type_lookup_lem2 = Q.prove (
`∀tenvC env tenv tvs senv v x t targs tparams idx.
  tenvC_ok tenvC ∧
  type_env tenvC senv env tenv ∧
  EVERY (check_freevars tvs []) targs ∧
  (lookup_tenv x 0 (bind_tvar tvs tenv) = SOME (LENGTH targs, t)) ∧
  (lookup x env = SOME (v,tparams))
  ⇒
  type_v tvs tenvC senv (do_tapp tparams (SOME targs) v) (deBruijn_subst 0 targs t)`,
induct_on `tenv` >>
rw [] >>
fs [lookup_tenv_def, bind_tvar_def] >>
qpat_assum `type_env tenvC senv env tenv_pat`
        (MP_TAC o SIMP_RULE (srw_ss ())
                         [Once (hd (tl (tl (CONJUNCTS type_v_cases))))]) >>
rw [] >>
fs [lookup_def, bind_def, emp_def, bind_tenv_def] >>
rw [] >>
cases_on `n'≠x` >>
rw [] >-
metis_tac [lookup_tenv_def] >>
`(n = LENGTH targs) ∧ (t = deBruijn_inc n tvs t')`
          by (cases_on `tvs` >>
              fs [lookup_tenv_def] >>
              metis_tac []) >>
rw [do_tapp_def] >>
metis_tac [type_v_freevars, type_subst, bind_tvar_def]);

val type_raise_eqn = Q.prove (
`!tenvC tenv r t. 
  type_e tenvC tenv (Raise r) t = check_freevars (num_tvs tenv) [] t`,
rw [Once type_e_cases]);

val type_env_eqn = Q.prove (
`!tenvC senv. 
  (type_env tenvC senv emp Empty = T) ∧
  (!n tvs t v env tenv. 
      type_env tenvC senv (bind n (v, SOME (tvs,t)) env) (bind_tenv n tvs t tenv) = 
      type_v tvs tenvC senv v t ∧ check_freevars tvs [] t ∧ type_env tenvC senv env tenv)`,
rw [Once type_v_cases] >-
rw [Once type_v_cases] >>
fs [bind_def, emp_def, bind_tenv_def] >>
metis_tac [type_v_freevars]);

val type_v_store_weak = Q.prove (
`(!tvs cenv senv v t.
   type_v tvs cenv senv v t ⇒ 
   !l v'. (lookup l senv = NONE) ⇒ type_v tvs cenv (bind l v' senv) v t) ∧
 (!tvs cenv senv vs ts.
   type_vs tvs cenv senv vs ts ⇒ 
   !l v'. (lookup l senv = NONE) ⇒ type_vs tvs cenv (bind l v' senv) vs ts) ∧
 (!cenv senv env tenv.
   type_env cenv senv env tenv ⇒ 
   !l v'. (lookup l senv = NONE) ⇒ type_env cenv (bind l v' senv) env tenv)`,
ho_match_mp_tac type_v_ind >>
rw [] >>
rw [Once type_v_cases] >|
[metis_tac [],
 metis_tac [],
 fs [lookup_def, bind_def] >>
     rw [] >>
     fs [],
 metis_tac []]);

val type_ctxts_store_weak = Q.prove (
`!dec_tvs tenvC senv cs t1 t2.
  type_ctxts dec_tvs tenvC senv cs t1 t2 ⇒
  !l v. (lookup l senv = NONE) ⇒ type_ctxts dec_tvs tenvC (bind l v senv) cs t1 t2`,
ho_match_mp_tac type_ctxts_ind >>
rw [] >>
rw [Once type_ctxts_cases] >>
qexists_tac `tenv` >>
qexists_tac `t1'` >>
rw [] >>
fs [type_ctxt_cases] >>
metis_tac [type_v_store_weak]);

(* If a step can be taken from a well-typed state, the resulting state has the
* same type *)
val exp_type_preservation = Q.prove (
`∀dec_tvs (tenvC:tenvC) envC s env e c t envC' s' env' e' c'.
  tenvC_ok tenvC ∧
  type_state dec_tvs tenvC (envC, s, env, e, c) t ∧
  (e_step (envC, s, env, e, c) = Estep (envC', s', env', e', c'))
  ⇒
  type_state dec_tvs tenvC (envC', s', env', e', c') t`,
rw [type_state_cases] >>
fs [e_step_def] >|
[`check_freevars tvs [] t1 ∧ check_freevars dec_tvs [] t`
           by metis_tac [type_ctxts_freevars] >>
     cases_on `e''` >>
     fs [push_def, is_value_def] >>
     rw [] >|
     [qpat_assum `type_ctxts a0 a1 b1 c1 d1 e1` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ctxts_cases]) >>
          rw [] >>
          fs [] >>
          `check_freevars 0 [] Tint` by rw [check_freevars_def] >>
          `tvs = 0` by metis_tac [context_invariant_determ] >>
          rw [] >>
          qpat_assum `context_invariant x0 x1 x2` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >> 
          rw [] >>
          fs [type_ctxt_cases] >>
          rw [] >-
          (cases_on `e` >>
               fs [] >>
               rw [] >>
               `type_v 0 tenvC senv (Litv (IntLit i)) Tint` by rw [Once type_v_cases] >>
               metis_tac [type_env_eqn, bind_tvar_def]) >>
          rw [type_raise_eqn, bind_tvar_def, num_tvs_def] >>
          metis_tac [type_raise_eqn, type_v_freevars, type_ctxts_freevars],
      qpat_assum `type_e a1 b1 c1 d1` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases] >>
          rw [type_ctxt_cases] >>
          fs [bind_tvar_def] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          rw [] >>
          metis_tac [],
      fs [return_def] >>
          rw [] >>
          qpat_assum `type_e tenvC tenv (Lit l) t1`
                    (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >>
          rw [] >>
          rw [Once (hd (CONJUNCTS type_v_cases))] >>
          metis_tac [],
      every_case_tac >>
          fs [return_def] >>
          rw [] >>
          qpat_assum `type_e tenvC tenv (Con s'' epat) t1`
                   (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [] >>
          qpat_assum `type_es tenvC tenv epat ts`
                   (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >|
          [qexists_tac `senv` >>
               qexists_tac `Tapp ts' tn` >>
               qexists_tac `tenv` >>
               rw [] >>
               rw [Once type_v_cases] >>
               rw [Once type_v_cases] >>
               metis_tac [check_freevars_def],
           rw [Once type_ctxts_cases, type_ctxt_cases] >>
               qexists_tac `senv`>>
               qexists_tac `t''`>>
               qexists_tac `tenv`>>
               ONCE_REWRITE_TAC [context_invariant_cases] >>
               rw [] >>
               qexists_tac `tvs` >>
               rw [] >|
               [qexists_tac `tenv`>>
                    qexists_tac `Tapp ts' tn`>>
                    rw [] >>
                    cases_on `ts` >>
                    fs [] >>
                    rw [] >>
                    qexists_tac `tvs` >>
                    rw [] >-
                    metis_tac [] >>
                    qexists_tac `[]` >>
                    qexists_tac `t'''` >>
                    rw [] >>
                    metis_tac [type_v_rules, APPEND, check_freevars_def],
                metis_tac []]],
      every_case_tac >>
          fs [return_def] >>
          rw [] >>
          qexists_tac `senv` >>
          qexists_tac `t1` >>
          qexists_tac `tenv` >>
          rw [] >>
          qpat_assum `type_e tenvC tenv (Var s'' o') t1`
                   (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >>
          rw [] >>
          qexists_tac `tvs` >>
          rw [] >>
          imp_res_tac type_v_freevars >>
          `num_tvs (bind_tvar tvs tenv) = tvs` 
                   by (fs [bind_tvar_def] >>
                       cases_on `tvs` >>
                       fs [num_tvs_def]) >>
          metis_tac [type_lookup_lem2],
      fs [return_def] >>
          rw [] >>
          qpat_assum `type_e tenvC tenv (Fun s'' o' e'') t1`
                   (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [] >>
          rw [bind_tvar_def, Once (hd (CONJUNCTS type_v_cases))] >>
          fs [bind_tvar_def] >>
          metis_tac [check_freevars_def],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [type_uop_def] >>
          every_case_tac >>
          rw [Once type_ctxts_cases, type_ctxt_cases, type_uop_def] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def, check_freevars_def] >|
          [metis_tac [check_freevars_def],
           metis_tac [check_freevars_def],
           metis_tac [check_freevars_def],
           metis_tac [check_freevars_def],
           metis_tac [check_freevars_def],
           qexists_tac `senv` >>
               qexists_tac `Tref t'` >>
               rw [] >>
               metis_tac [check_freevars_def],
           metis_tac [check_freevars_def]],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def] >>
          metis_tac [type_e_freevars, type_v_freevars],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def] >>
          metis_tac [type_e_freevars, type_v_freevars],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def] >>
          metis_tac [],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def] >>
          metis_tac [type_e_freevars, type_v_freevars],
      qpat_assum `type_e x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          fs [bind_tvar_def] >|
          [qexists_tac `senv` >>
               qexists_tac `t1'` >>
               qexists_tac `tenv` >>
               rw [] >>
               metis_tac [arithmeticTheory.ADD, arithmeticTheory.ADD_COMM,
                          num_tvs_def, type_v_freevars, tenv_ok_def,
                          type_e_freevars],
           qexists_tac `senv` >>
               qexists_tac `t1'` >>
               qexists_tac `tenv` >>
               rw [] >>
               metis_tac [arithmeticTheory.ADD, arithmeticTheory.ADD_COMM,
                          num_tvs_def, type_v_freevars, tenv_ok_def,
                          type_e_freevars]],
      every_case_tac >>
          fs [] >>
          rw [] >>
          qpat_assum `type_e tenvC tenv epat t1`
              (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >>
          rw [build_rec_env_merge] >>
          qexists_tac `senv` >>
          qexists_tac `t1` >>
          qexists_tac `bind_var_list tvs tenv' tenv` >>
          rw [] >>
          fs [bind_tvar_def] >>
          qexists_tac `0` >>
          rw [] >>
          metis_tac [type_recfun_env, type_env_merge, bind_tvar_def]],
 `check_freevars tvs [] t1 ∧ check_freevars dec_tvs [] t` 
         by metis_tac [type_ctxts_freevars] >>
     fs [continue_def, push_def] >>
     cases_on `c` >>
     fs [] >>
     cases_on `h` >>
     fs [] >>
     cases_on `q` >>
     fs [] >>
     every_case_tac >>
     fs [return_def] >>
     rw [] >>
     qpat_assum `type_ctxts x0 x1 x2 x3 x4 x5` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ctxts_cases]) >>
     fs [type_ctxt_cases] >>
     rw [] >>
     qpat_assum `context_invariant x0 x1 x2` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >> 
     TRY (qpat_assum `context_invariant x0 x1 x2` 
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases])) >|
     [metis_tac [],
      rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          rw [bind_tvar_def] >>
          metis_tac [type_v_freevars, type_e_freevars, type_ctxts_freevars],
      fs [do_app_def] >>
          cases_on `o'` >>
          fs [] >|
          [every_case_tac >>
               fs [] >>
               rw [] >>
               fs [hd (CONJUNCTS type_v_cases)] >>
               rw [] >>
               fs [type_op_cases] >>
               rw [Once type_e_cases] >>
               metis_tac [check_freevars_def],
           every_case_tac >>
               fs [] >>
               rw [] >>
               fs [hd (CONJUNCTS type_v_cases)] >>
               rw [] >>
               fs [type_op_cases] >>
               rw [] >>
               rw [Once type_e_cases] >>
               metis_tac [check_freevars_def],
           every_case_tac >>
               fs [] >>
               rw [] >>
               fs [hd (CONJUNCTS type_v_cases)] >>
               rw [] >>
               fs [type_op_cases] >>
               rw [] >>
               rw [Once type_e_cases] >>
               metis_tac [check_freevars_def],
           every_case_tac >>
               fs [] >>
               rw [] >|
               [qpat_assum `type_v a tenvC senv (Closure l s' o' e) t1'`
                     (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
                    fs [] >>
                    rw [] >>
                    fs [type_op_cases] >>
                    rw [] >>
                    rw [Once type_v_cases, add_tvs_def] >>
                    fs [bind_tvar_def] >>
                    metis_tac [],
                qpat_assum `type_v a tenvC senv (Recclosure l l0 s') t1'`
                     (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
                    fs [] >>
                    rw [] >>
                    fs [type_op_cases] >>
                    rw [] >>
                    imp_res_tac type_recfun_lookup >>
                    rw [add_tvs_def] >>
                    qexists_tac `senv` >>
                    qexists_tac `t2` >>
                    qexists_tac `bind_tenv q' 0 t1 (bind_var_list 0 tenv''' (bind_tvar 0 tenv''))` >>
                    rw [add_tvs_def] >>
                    rw [Once type_v_cases, bind_def, bind_tenv_def] >>
                    fs [check_freevars_def] >>
                    rw [build_rec_env_merge] >>
                    fs [bind_tvar_def] >>
                    qexists_tac `0` >>
                    rw [] >>
                    fs [bind_tenv_def] >>
                    metis_tac [bind_tvar_def, type_recfun_env, type_env_merge]],
           every_case_tac >>
               fs [] >>
               rw [Once type_e_cases] >>
               qpat_assum `type_v x0 x1 x2 x3 x4` (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
               fs [type_op_cases] >>
               rw [] >>
               fs [store_assign_def, type_s_def, store_lookup_def] >>
               rw [EL_LUPDATE] >>
               qexists_tac `senv` >>
               qexists_tac `tenv'` >>
               rw [] >>
               qexists_tac `0` >>
               rw [] >>
               metis_tac [check_freevars_def]],
      fs [do_log_def] >>
           every_case_tac >>
           fs [] >>
           rw [] >>
           fs [Once (hd (CONJUNCTS type_v_cases))] >>
           metis_tac [bind_tvar_def, type_e_rules],
      fs [do_if_def] >>
           every_case_tac >>
           fs [] >>
           rw [] >>
           metis_tac [bind_tvar_def],
      rw [Once type_e_cases] >>
          metis_tac [bind_tvar_def, num_tvs_def, arithmeticTheory.ADD, type_v_freevars],
      rw [Once type_ctxts_cases, type_ctxt_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          rw [] >>
          fs [RES_FORALL] >>
          metis_tac [type_ctxts_freevars],
      fs [RES_FORALL, FORALL_PROD] >>
          rw [] >>
          metis_tac [bind_tvar_def, pmatch_type_preservation],
      rw [add_tvs_def, Once type_v_cases, bind_def] >>
          qexists_tac `senv` >>
          qexists_tac `t2` >>
          qexists_tac `bind_tenv s'' tvs t1 tenv'` >>
          rw [emp_def, bind_tenv_def] >>
          qexists_tac `0` >> 
          rw [bind_tvar_def] >>
          metis_tac [bind_tenv_def],
      `context_invariant dec_tvs c' tvs'` by metis_tac [context_invariant_rules] >>
          qpat_assum `(c' = []) ∧ (tvs' = dec_tvs) ∨ P` (fn _ => ALL_TAC) >>
          qpat_assum `context_invariant dec_tvs ((Ccon s'' l () [],env')::c') tvs` 
                 (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once context_invariant_cases]) >>
          fs [] >>    
          rw [Once (hd (CONJUNCTS type_v_cases))] >>
          imp_res_tac type_es_length >>
          fs [] >>
          `ts2 = []` by
                  (cases_on `ts2` >>
                   fs []) >>
          fs [] >>
          rw [] >>
          rw [type_vs_end_lem] >>
          fs [] >>
          metis_tac [context_invariant_determ, rich_listTheory.MAP_REVERSE],
      qpat_assum `type_es tenvC tenv' (e'::t'') ts2`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >>
          rw [type_ctxt_cases, Once type_ctxts_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          rw [] >>
          qexists_tac `senv` >>
          qexists_tac `t''''` >>
          qexists_tac `tenv'` >>
          qexists_tac `tvs'` >>
          rw [] >>
          qexists_tac `tenv'` >>
          qexists_tac `Tapp ts' tn` >>
          qexists_tac `tvs'` >>
          rw [] >>
          cases_on `ts2` >>
          fs [] >>
          rw [] >>
          qexists_tac `ts1++[t''']` >>
          rw [] >>
          metis_tac [context_invariant_determ, type_vs_end_lem],
      qpat_assum `type_es tenvC tenv' (e'::t'') ts2`
                (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_e_cases]) >>
          fs [] >>
          rw [type_ctxt_cases, Once type_ctxts_cases] >>
          ONCE_REWRITE_TAC [context_invariant_cases] >>
          rw [] >>
          qexists_tac `senv` >>
          qexists_tac `t''''` >>
          qexists_tac `tenv'` >>
          qexists_tac `tvs'` >>
          rw [] >>
          qexists_tac `tenv'` >>
          qexists_tac `Tapp ts' tn` >>
          qexists_tac `tvs'` >>
          rw [] >>
          cases_on `ts2` >>
          fs [] >>
          rw [] >>
          qexists_tac `ts1++[t''']` >>
          rw [] >>
          metis_tac [context_invariant_determ, type_vs_end_lem],
      cases_on `u` >>
          fs [type_uop_def, do_uapp_def, store_alloc_def, LET_THM] >>
          rw [] >|
          [rw [Once (hd (CONJUNCTS type_v_cases))] >>
               qexists_tac `bind (LENGTH s) t1 senv` >>
               qexists_tac `Tref t1` >>
               qexists_tac `tenv'` >>
               qexists_tac `0` >>
               rw [] >>
               `lookup (LENGTH s) senv = NONE`
                       by (fs [type_s_def, store_lookup_def] >>
                           `~(LENGTH s < LENGTH s)` by decide_tac >>
                           `~(?t. lookup (LENGTH s) senv = SOME t)` by metis_tac [] >>
                           fs [] >>
                           cases_on `lookup (LENGTH s) senv` >>
                           fs []) >|
               [metis_tac [type_ctxts_store_weak],
                metis_tac [type_v_store_weak],
                fs [type_s_def, lookup_def, bind_def, store_lookup_def] >>
                    rw [] >-
                    decide_tac >|
                    [rw [rich_listTheory.EL_LENGTH_APPEND] >>
                         metis_tac [bind_def, type_v_store_weak],
                     `l < LENGTH s` by decide_tac >>
                         rw [rich_listTheory.EL_APPEND1] >>
                         metis_tac [type_v_store_weak, bind_def]],
                rw [lookup_def, bind_def]],
           cases_on `t1` >>
               fs [] >>
               cases_on `v` >>
               fs [store_lookup_def] >>
               cases_on `n < LENGTH s` >>
               fs [] >>
               rw [] >>
               qpat_assum `type_v a0 a1 b2 c3 d4`
                     (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_v_cases]) >>
               fs [type_s_def, store_lookup_def] >>
               metis_tac []]]]);

val e_step_ctor_env_same = Q.prove (
`!cenv s env e c cenv' s' env' e' c'.
  (e_step (cenv,s,env,e,c) = Estep (cenv',s',env',e',c')) ⇒ (cenv = cenv')`,
rw [e_step_def] >>
every_case_tac >>
fs [push_def, return_def, continue_def] >>
every_case_tac >>
fs []);

val exp_type_soundness_help = Q.prove (
`!st1 st2. e_step_reln^* st1 st2 ⇒
  ∀tenvC s tenvE envC envE e c envC' s' envE' e' c' t dec_tvs.
    (st1 = (envC,s,envE,e,c)) ∧
    (st2 = (envC',s',envE',e',c')) ∧
    tenvC_ok tenvC ∧
    consistent_con_env envC tenvC ∧
    consistent_con_env2 envC tenvC ∧
    type_state dec_tvs tenvC st1 t
    ⇒
    (envC = envC') ∧
    type_state dec_tvs tenvC st2 t`,
ho_match_mp_tac RTC_INDUCT >>
rw [e_step_reln_def] >>
`?envC' s' envE' e' c'. st1' = (envC',s',envE',e',c')`
        by (PairCases_on `st1'` >>
            metis_tac []) >>
rw [] >>
metis_tac [e_step_ctor_env_same, exp_type_preservation]);

val exp_type_soundness = Q.store_thm ("exp_type_soundness",
`!tenvC tenvS tenvE s e t envC envE.
  tenvC_ok tenvC ∧
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  type_env tenvC tenvS envE tenvE ∧
  type_s tenvC tenvS s ∧
  type_e tenvC tenvE e t
  ⇒
  e_diverges envC s envE e ∨
  ?s' r. (r ≠ Rerr Rtype_error) ∧ small_eval envC s envE e [] (s',r)`,
rw [e_diverges_def, METIS_PROVE [] ``x ∨ y = ~x ⇒ y``, d_step_reln_def] >>
`type_state 0 tenvC (envC,s,envE,Exp e,[]) t`
         by (rw [type_state_cases] >>
             qexists_tac `tenvS` >>
             qexists_tac `t` >>
             qexists_tac `tenvE` >>
             qexists_tac `0` >>
             rw [] >>
             metis_tac [bind_tvar_def, context_invariant_rules,
                        type_ctxts_rules, type_v_freevars, type_e_freevars]) >>
imp_res_tac exp_type_soundness_help >>
fs [] >>
rw [] >>
fs [e_step_reln_def] >>
`final_state (cenv',s',env',e',c')`
           by metis_tac [exp_type_progress] >>
Cases_on `e'` >>
Cases_on `c'` >>
TRY (Cases_on `e''`) >>
fs [final_state_def] >>
qexists_tac `s'` >|
[qexists_tac `Rerr (Rraise e')`,
 qexists_tac `Rval v`] >>
rw [small_eval_def] >>
metis_tac []);

val tenvC_weakeningv = Q.prove (
`(!tvs tenvC senv v t. type_v tvs tenvC senv v t ⇒
    !tenvC'. disjoint_env tenvC tenvC' ⇒ type_v tvs (merge tenvC' tenvC) senv v t) ∧
 (!tvs tenvC senv vs ts. type_vs tvs tenvC senv vs ts ⇒
    !tenvC'. disjoint_env tenvC tenvC' ⇒ type_vs tvs (merge tenvC' tenvC) senv vs ts) ∧
 (!tenvC senv env tenv. type_env tenvC senv env tenv ⇒
    !tenvC'. disjoint_env tenvC tenvC' ⇒ type_env (merge tenvC' tenvC) senv env tenv)`,
ho_match_mp_tac type_v_ind >>
rw [] >>
rw [Once type_v_cases] >>
fs [] >>
RES_TAC >>
metis_tac [lookup_disjoint, tenvC_pat_weakening, tenvC_weakening]);

val store_extension_def = Define `
store_extension s s' =
  (s' = s) ∨ 
  (?l v. (store_lookup l s = NONE) ∧ ((s',l) = store_alloc v s)) ∨
  (?l v. (SOME s' = store_assign l v s))`;

val exp_step_store = Q.prove (
`!envC s env e c envC' s' env' e' c'.
  (e_step (envC,s,env,e,c) = Estep (envC,s',env',e',c')) 
  ⇒
  store_extension s s'`,
rw [store_extension_def, e_step_def, continue_def, push_def, return_def] >>
cases_on `e` >>
fs [] >|
[cases_on `e''` >>
     fs [] >>
     rw [] >-
     (cases_on `c` >>
          fs [] >>
          PairCases_on `h` >>
          fs [] >>
          cases_on `h0` >>
          fs [] >>
          every_case_tac >>
          fs [] >>
          metis_tac []) >>
     every_case_tac >>
     fs [] >>
     metis_tac [],
 cases_on `c` >>
     fs [] >>
     PairCases_on `h` >>
     fs [] >>
     cases_on `h0` >>
     fs [do_uapp_def, do_app_def] >|
     [every_case_tac >>
          fs [] >>
          metis_tac [],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      cases_on `o0` >>
          fs [] >>
          cases_on `o'` >>
          fs [] >|
          [cases_on `v'` >>
               fs [] >>
               cases_on `l` >>
               fs [] >>
               cases_on `v` >>
               fs [] >>
               cases_on `l` >>
               fs [] >>
               every_case_tac >>
               fs [] >>
               metis_tac [],
           cases_on `v'` >>
               fs [] >>
               cases_on `l` >>
               fs [] >>
               cases_on `v` >>
               fs [] >>
               cases_on `l` >>
               fs [] >>
               every_case_tac >>
               fs [] >>
               metis_tac [],
           every_case_tac >>
               fs [] >>
               metis_tac [],
           cases_on `v'` >>
               fs [] >>
               every_case_tac >>
               fs [] >>
               rw [] >>
               metis_tac []],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      every_case_tac >>
          fs [] >>
          metis_tac [],
      cases_on `o'` >>
          fs [] >>
          cases_on `u` >>
          fs [] >>
          cases_on `v` >>
          fs [] >>
          every_case_tac >>
          fs [store_alloc_def, LET_THM] >>
          rw [store_assign_def, store_lookup_def]]]);

(*
val type_v_store_weak2 = Q.prove (
`(!tvs cenv senv v t.
   type_v tvs cenv senv v t ⇒ 
   !senv' s s'. 
     type_s cenv senv s ∧
     type_s cenv senv' s' ∧
     store_extension s s' 
     ⇒
     type_v tvs cenv senv' v t) ∧
 (!tvs cenv senv vs ts.
   type_vs tvs cenv senv vs ts ⇒ 
   !senv' s s'. 
     type_s cenv senv s ∧
     type_s cenv senv' s' ∧
     store_extension s s' 
     ⇒
     type_vs tvs cenv senv' vs ts) ∧
 (!cenv senv env tenv.
   type_env cenv senv env tenv ⇒ 
   !senv' s s'. 
     type_s cenv senv s ∧
     type_s cenv senv' s' ∧
     store_extension s s' 
     ⇒
     type_env cenv senv' env tenv)`,

ho_match_mp_tac type_v_ind >>
rw [] >>
rw [Once type_v_cases] >|
[metis_tac [],
 metis_tac [],
 metis_tac [],
 all_tac,
 metis_tac [],
 metis_tac [],
 metis_tac []]

 fs [store_extension_def, store_lookup_def, store_assign_def, store_alloc_def,
     type_s_def] >>
     rw [] >>
     fs [] >>


     metis_tac []

 fs [lookup_def, bind_def] >>
     rw [] >>
     fs [],
     *)

val type_env_weak = Q.prove (
`!s s' tenvC tenvS' tenvS envE tenv.
  store_extension s s' ∧
  type_s tenvC tenvS s ∧
  type_s tenvC tenvS' s' ∧
  type_env tenvC tenvS envE tenv
  ⇒
  type_env tenvC tenvS' envE tenv`,
cheat);

val TAC =
PairCases_on `p'` >>
rw [] >>
fs [merge_def, emp_def, get_first_tenv_def, build_ctor_tenv_def] >>
`type_state tvs tenvC (p'0,p'1,p'2,p'3,p'4) t ∧ (p'0 = envC)`
          by metis_tac [exp_type_preservation,e_step_ctor_env_same] >>
rw [] >>
`?tenvS. type_s tenvC tenvS p'1` 
         by (fs [type_state_cases] >>
             metis_tac []) >>
metis_tac [type_env_weak, exp_step_store];

val type_preservation = Q.prove (
`!tenvC envS envC envE ds c envC' envS' envE' ds' c' tenvE tenvC' st' tenvC''.
  tenvC_ok tenvC ∧
  (tenvC'' = build_ctor_tenv (get_first_tenv ds c)) ∧
  type_d_state tenvC (envC,envS,envE,ds,c) (merge tenvC'' tenvC') tenvE ∧
  (d_step (envC,envS,envE,ds,c) = Dstep (envC',envS',envE',ds',c'))
  ⇒
  type_d_state (merge (REVERSE tenvC'') tenvC) (envC',envS',envE',ds',c') tenvC' tenvE`,
rw [type_d_state_cases] >>
fs [d_step_def] >|
[every_case_tac >>
     fs [] >>
     rw [] >|
     [pop_assum (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ds_cases]) >>
          rw [type_state_cases, Once type_ctxts_cases, type_ctxt_cases] >>
          fs [build_ctor_tenv_def,get_first_tenv_def, merge_def, emp_def,
              type_d_cases] >>
          rw [Once context_invariant_cases] >>
          qexists_tac `senv` >>
          qexists_tac `tenv` >>
          qexists_tac `tenv''` >>
          qexists_tac `t` >>
          rw [] >>
          metis_tac [REVERSE_DEF,APPEND, type_p_freevars, bind_tvar_def],
      qpat_assum `type_ds a b c d e`
                 (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ds_cases]) >>
          fs [type_d_cases] >>
          rw [build_rec_env_merge] >>
          fs [build_ctor_tenv_def, get_first_tenv_def, merge_def, emp_def] >>
          metis_tac [merge_def, type_recfun_env, type_env_merge_lem1],
      qpat_assum `type_ds a b c d e`
                 (ASSUME_TAC o SIMP_RULE (srw_ss()) [Once type_ds_cases]) >>
          fs [type_d_cases, get_first_tenv_def, merge_def] >>
          qexists_tac `senv` >>
          qexists_tac `tenv` >>
          rw [] >>
          fs [type_s_def] >>
          metis_tac [tenvC_weakeningv, merge_def, check_ctor_tenv_dups,
                     disjoint_env_rev]],
 qpat_assum `ALL_DISTINCT (pat_bindings p [])` ASSUME_TAC >>
     fs [] >>
     every_case_tac >>
     fs [] >>
     rw [] >|
     [TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      fs [type_state_cases, Once type_ctxts_cases, merge_def,emp_def,
          get_first_tenv_def, build_ctor_tenv_def] >>
          fs [type_state_cases, Once type_ctxts_cases, merge_def,emp_def,
              get_first_tenv_def, build_ctor_tenv_def] >>
          fs [Once context_invariant_cases] >>
          `store_extension envS' envS'` by rw [store_extension_def] >>
          metis_tac [pmatch_type_preservation, type_env_weak],
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC,
      TAC]]);

val def_final_state_def = Define `
  def_final_state (envC,envS,envE,ds,c) = (c = NONE) ∧ (ds = [])`;

val consistent_cenv_no_dups = Q.prove (
`!l envC tenvC.
  consistent_con_env envC tenvC ∧
  check_dup_ctors l tenvC
  ⇒
  check_dup_ctors l envC`,
induct_on `l` >>
rw [check_dup_ctors_def] >>
fs [RES_FORALL] >>
rw [] >|
[PairCases_on `h` >>
     fs [] >>
     rw [] >>
     `(λ(tvs,tn,condefs).
        ∀x. MEM x condefs ⇒ (λ(n,ts). lookup n tenvC = NONE) x) (h0,h1,h2)`
              by metis_tac [] >>
     fs [] >>
     rw [] >>
     PairCases_on  `x` >>
     fs [] >>
     RES_TAC >>
     fs [] >>
     metis_tac [consistent_con_env_thm],
 `(λ(tvs,tn,condefs).
    ∀x. MEM x condefs ⇒ (λ(n,ts). lookup n tenvC = NONE) x) x`
              by metis_tac [] >>
     PairCases_on `x` >>
     fs [] >>
     rw [] >>
     fs [] >>
     RES_TAC >>
     fs [] >>
     PairCases_on `x` >>
     fs [] >>
     metis_tac [consistent_con_env_thm]]);

val type_progress = Q.prove (
`!tenvC envC envS envE ds c tenvC' tenvE.
  type_d_state tenvC (envC,envS,envE,ds,c) tenvC' tenvE ∧
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  ~def_final_state (envC,envS,envE,ds,c)
  ⇒
  (?envC' envS' envE' ds' c'. d_step (envC,envS,envE,ds,c) = Dstep (envC',envS',envE',ds',c'))
  ∨
  (?err. d_step (envC,envS,envE,ds,c) = Draise err)`,
rw [type_d_state_cases, d_step_def, def_final_state_def] >>
rw [] >|
[every_case_tac >>
     fs [] >|
     [fs [Once type_ds_cases, type_d_cases] >>
          metis_tac [type_funs_distinct],
      fs [Once type_ds_cases, type_d_cases, check_ctor_tenv_def] >>
          metis_tac [consistent_cenv_no_dups]],
 every_case_tac >>
     fs [] >|
     [metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      fs [type_state_cases, Once type_ctxts_cases] >>
          fs [type_state_cases, Once type_ctxts_cases] >>
          metis_tac [pmatch_type_progress, match_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct]],
 every_case_tac >>
     fs [] >|
     [metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      fs [type_state_cases, Once type_ctxts_cases] >>
          fs [type_state_cases, Once type_ctxts_cases] >>
          metis_tac [pmatch_type_progress, match_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct],
      metis_tac [exp_type_progress, final_state_def, e_step_result_distinct]]]);

val consistent_con_preservation = Q.prove (
`!tenvC envS envC envE ds c envC' envS' envE' ds' c' tenvE tenvC' st' tds.
  (tds = get_first_tenv ds c) ∧
  check_ctor_tenv tenvC tds ∧
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  (d_step (envC,envS,envE,ds,c) = Dstep (envC',envS',envE',ds',c'))
  ⇒
  consistent_con_env envC' (merge (REVERSE (build_ctor_tenv tds)) tenvC) ∧
  consistent_con_env2 envC' (merge (REVERSE (build_ctor_tenv tds)) tenvC)`,
rw [d_step_def] >>
cases_on `c` >>
fs [] >|
[cases_on `ds` >>
     fs [] >>
     cases_on `h` >>
     fs [] >>
     fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
     full_case_tac >>
     fs [] >>
     metis_tac [extend_consistent_con],
 PairCases_on `x` >>
     fs [] >>
     cases_on `x5` >>
     fs [] >|
     [cases_on `e` >>
          fs [] >>
          full_case_tac >>
          fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
          full_case_tac >>
          fs [],
      cases_on `x6` >>
          fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
          full_case_tac >>
          fs [] >>
          full_case_tac >>
          fs []],
 cases_on `ds` >>
     fs [] >>
     cases_on `h` >>
     fs [] >>
     fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
     full_case_tac >>
     fs [] >>
     metis_tac [extend_consistent_con2],
 PairCases_on `x` >>
     fs [] >>
     cases_on `x5` >>
     fs [] >|
     [cases_on `e` >>
          fs [] >>
          full_case_tac >>
          fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
          full_case_tac >>
          fs [],
      cases_on `x6` >>
          fs [get_first_tenv_def, merge_def, build_ctor_tenv_empty] >>
          full_case_tac >>
          fs [] >>
          full_case_tac >>
          fs []]]); 

val check_ctor_tenv_of_first_tenv = Q.prove (
`type_d_state tenvC (envC,envS,envE,ds,c) tenvC' tenvE
 ⇒
 check_ctor_tenv tenvC (get_first_tenv ds c)`,
rw [type_d_state_cases] >>
rw [get_first_tenv_def] >|
[fs [Once type_ds_cases] >-
     rw [check_ctor_tenv_def, check_dup_ctors_def, RES_FORALL, LET_THM] >>
     fs [type_d_cases] >>
     rw [check_ctor_tenv_def, check_dup_ctors_def, RES_FORALL, LET_THM],
 rw [check_ctor_tenv_def, check_dup_ctors_def, RES_FORALL, LET_THM]]);

val check_ctor_tenvC_ok = Q.prove (
`!tenvC c. check_ctor_tenv tenvC c ⇒ tenvC_ok (build_ctor_tenv c)`,
induct_on `c` >>
rw [build_ctor_tenv_def, tenvC_ok_def] >>
PairCases_on `h` >>
fs [check_ctor_tenv_def, EVERY_MAP] >|
[fs [EVERY_MEM] >>
     rw [] >>
     PairCases_on `x` >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [],
 fs [EVERY_MEM] >>
     rw [] >>
     PairCases_on `e` >>
     fs [MEM_FLAT, MEM_MAP] >>
     rw [] >>
     PairCases_on `y` >>
     fs [MEM_MAP] >>
     PairCases_on `y` >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     res_tac >>
     fs []]);

val type_soundness_help = Q.prove (
`!st1 st2. d_step_reln^* st1 st2 ⇒
  ∀tenvC tenvC' tenvE envC s envE ds c envC' s' envE' ds' c'.
    (st1 = (envC,s,envE,ds,c)) ∧
    (st2 = (envC',s'envE',ds',c')) ∧
    tenvC_ok tenvC ∧
    consistent_con_env envC tenvC ∧
    consistent_con_env2 envC tenvC ∧
    type_d_state tenvC st1 tenvC' tenvE
    ⇒
    ?tenvC1 tenvC2.
      (tenvC' = merge tenvC1 tenvC2) ∧
      tenvC_ok (merge (REVERSE tenvC1) tenvC) ∧
      consistent_con_env envC' (merge (REVERSE tenvC1) tenvC) ∧
      consistent_con_env2 envC' (merge (REVERSE tenvC1) tenvC) ∧
      type_d_state (merge (REVERSE tenvC1) tenvC) st2 tenvC2 tenvE`,
ho_match_mp_tac RTC_INDUCT >>
rw [] >-
(rw [merge_def] >>
     metis_tac [APPEND, REVERSE_DEF]) >>
fs [d_step_reln_def] >>
`?envC' s' envE' ds' c'. st1' = (envC',s',envE',ds',c')`
        by (PairCases_on `st1'` >>
            metis_tac []) >>
rw [] >>
`?tenvC2. tenvC' = merge (build_ctor_tenv (get_first_tenv ds c)) tenvC2`
         by (cases_on `ds` >>
             fs [get_first_tenv_def,merge_def,get_first_tenv_def,
                 build_ctor_tenv_def, type_d_state_cases] >>
             cases_on `h` >>
             fs [Once type_ds_cases, Once type_d_cases, build_ctor_tenv_def] >>
             rw [] >>
             metis_tac [merge_def]) >>
`type_d_state (merge (REVERSE (build_ctor_tenv (get_first_tenv ds c))) tenvC)
              (envC'',s',envE',ds'',c'') tenvC2 tenvE`
         by metis_tac [type_preservation] >>
`consistent_con_env envC''
        (merge (REVERSE (build_ctor_tenv (get_first_tenv ds c))) tenvC) ∧
 consistent_con_env2 envC''
        (merge (REVERSE (build_ctor_tenv (get_first_tenv ds c))) tenvC)`
          by metis_tac [check_ctor_tenv_of_first_tenv,
                        consistent_con_preservation] >>
`tenvC_ok (merge (REVERSE (build_ctor_tenv (get_first_tenv ds c))) tenvC)`
          by (fs [tenvC_ok_def, merge_def, rich_listTheory.ALL_EL_REVERSE] >>
              metis_tac [check_ctor_tenvC_ok, tenvC_ok_def,
                         check_ctor_tenv_of_first_tenv]) >>
res_tac >>
qexists_tac `merge (build_ctor_tenv (get_first_tenv ds c)) tenvC1` >>
qexists_tac `tenvC2'` >>
fs [merge_def] >>
rw [REVERSE_APPEND]);

val type_soundness = Q.store_thm ("type_soundness",
`!tenvC tenvS tenvE ds tenvC' tenvE' envC s envE.
  tenvC_ok tenvC ∧
  consistent_con_env envC tenvC ∧
  consistent_con_env2 envC tenvC ∧
  type_env tenvC tenvS envE tenvE ∧
  type_s tenvC tenvS s ∧
  type_ds tenvC tenvE ds tenvC' tenvE'
  ⇒
  diverges envC s envE ds ∨
  ?s' r. (r ≠ Rerr Rtype_error) ∧ d_small_eval envC s envE ds NONE (s', r)`,
rw [diverges_def, METIS_PROVE [] ``x ∨ y = ~x ⇒ y``, d_step_reln_def] >>
`type_d_state tenvC (envC,s,envE,ds,NONE) tenvC' tenvE'`
         by (rw [type_d_state_cases] >>
             metis_tac []) >>
imp_res_tac type_soundness_help >>
fs [] >>
rw [] >>
`def_final_state (cenv',s',env',ds',c') ∨
 ?err. d_step (cenv',s',env',ds',c') = Draise err`
           by metis_tac [type_progress] >|
[fs [def_final_state_def] >>
     rw [] >>
     qexists_tac `s'` >>
     qexists_tac `Rval (cenv',env')` >>
     rw [d_small_eval_def] >>
     metis_tac [],
 qexists_tac `d_state_to_store s' c'` >>
     qexists_tac `Rerr (Rraise err)` >>
     rw [d_small_eval_def] >>
     metis_tac []]);

val _ = export_theory ();
