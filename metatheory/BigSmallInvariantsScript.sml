(*Generated by Lem from bigSmallInvariants.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open TypeSystemTheory BigStepTheory SmallStepTheory SemanticPrimitivesTheory AstTheory TokensTheory LibTheory

val _ = new_theory "BigSmallInvariants"

(*open Lib*)
(*open Ast*)
(*open SemanticPrimitives*)
(*open SmallStep*)
(*open BigStep*)

(* ------ Auxiliary relations for proving big/small step equivalence ------ *)

(*val evaluate_ctxt : envM -> envC -> count_store -> envE -> ctxt_frame -> v -> count_store * result v -> bool*)
(*val evaluate_ctxts : envM -> envC -> count_store -> list ctxt -> result v -> count_store * result v -> bool*)
(*val evaluate_state : state -> count_store * result v -> bool*)

val _ = Hol_reln `

(! menv cenv s env v1 e2 var.
T
==>
evaluate_ctxt menv cenv s env (Chandle ()  var e2) v1 (s, Rval v1))

/\

(! menv cenv env op e2 v1 v2 env' e3 bv s1 s2 count s3.
(
evaluate F menv cenv s1 env e2 ((count,s2), Rval v2) /\
(
do_app s2 env op v1 v2 = SOME (s3,env', e3)) /\
evaluate F menv cenv (count, s3) env' e3 bv)
==>
evaluate_ctxt menv cenv s1 env (Capp1 op ()  e2) v1 bv)

/\

(! menv cenv env op e2 v1 v2 s1 s2 count.
(
evaluate F menv cenv s1 env e2 ((count,s2), Rval v2) /\
(
do_app s2 env op v1 v2 = NONE))
==>
evaluate_ctxt menv cenv s1 env (Capp1 op ()  e2) v1 ((count, s2), Rerr Rtype_error))

/\

(! menv cenv env op e2 v1 err s s'.
(
evaluate F menv cenv s env e2 (s', Rerr err))
==>
evaluate_ctxt menv cenv s env (Capp1 op ()  e2) v1 (s', Rerr err))

/\

(! menv cenv env op v1 v2 env' e3 bv s1 s2 count.
((
do_app s1 env op v1 v2 = SOME (s2, env', e3)) /\
evaluate F menv cenv (count, s2) env' e3 bv)
==>
evaluate_ctxt menv cenv (count,s1) env (Capp2 op v1 () ) v2 bv)

/\

(! menv cenv env op v1 v2 s count.
(do_app s env op v1 v2 = NONE)
==>
evaluate_ctxt menv cenv (count,s) env (Capp2 op v1 () ) v2 ((count, s), Rerr Rtype_error))

/\

(! menv cenv env uop v v' s1 s2 count.
(do_uapp s1 uop v = SOME (s2,v'))
==>
evaluate_ctxt menv cenv (count,s1) env (Cuapp uop () ) v ((count,s2), Rval v'))

/\

(! menv cenv env uop v s count.
(do_uapp s uop v = NONE)
==>
evaluate_ctxt menv cenv (count,s) env (Cuapp uop () ) v ((count,s), Rerr Rtype_error))

/\

(! menv cenv env op e2 v e' bv s.
((
do_log op v e2 = SOME e') /\
evaluate F menv cenv s env e' bv)
==>
evaluate_ctxt menv cenv s env (Clog op ()  e2) v bv)

/\

(! menv cenv env op e2 v s.
(do_log op v e2 = NONE)
==>
evaluate_ctxt menv cenv s env (Clog op ()  e2) v (s, Rerr Rtype_error))

/\
(! menv cenv env e2 e3 v e' bv s.
((
do_if v e2 e3 = SOME e') /\
evaluate F menv cenv s env e' bv)
==>
evaluate_ctxt menv cenv s env (Cif ()  e2 e3) v bv)

/\

(! menv cenv env e2 e3 v s.
(do_if v e2 e3 = NONE)
==>
evaluate_ctxt menv cenv s env (Cif ()  e2 e3) v (s, Rerr Rtype_error))

/\

(! menv cenv env pes v bv s.
(
evaluate_match F menv cenv s env v pes bv)
==>
evaluate_ctxt menv cenv s env (Cmat ()  pes) v bv)

/\

(! menv cenv env n e2 v bv s.
(
evaluate F menv cenv s (bind n v env) e2 bv)
==>
evaluate_ctxt menv cenv s env (Clet n ()  e2) v bv)

/\

(! menv cenv env cn es vs v vs' s1 s2.
(
do_con_check cenv cn ( LENGTH vs + LENGTH es + 1) /\
evaluate_list F menv cenv s1 env es (s2, Rval vs'))
==>
evaluate_ctxt menv cenv s1 env (Ccon cn vs ()  es) v (s2, Rval (Conv cn ( REVERSE vs ++ ([v] ++ vs')))))

/\

(! menv cenv env cn es vs v s. ( ~  (do_con_check cenv cn ( LENGTH vs + LENGTH es + 1)))
==>
evaluate_ctxt menv cenv s env (Ccon cn vs ()  es) v (s, Rerr Rtype_error))

/\

(! menv cenv env cn es vs v err s s'.
(
do_con_check cenv cn ( LENGTH vs + LENGTH es + 1) /\
evaluate_list F menv cenv s env es (s', Rerr err))
==>
evaluate_ctxt menv cenv s env (Ccon cn vs ()  es) v (s', Rerr err))`;

val _ = Hol_reln `

(! menv cenv res s.
T
==>
evaluate_ctxts menv cenv s [] res (s, res))

/\

(! menv cenv c cs env v res bv s1 s2.
(
evaluate_ctxt menv cenv s1 env c v (s2, res) /\
evaluate_ctxts menv cenv s2 cs res bv)
==>
evaluate_ctxts menv cenv s1 ((c,env) ::cs) (Rval v) bv)

/\

(! menv cenv c cs env err s bv.
(evaluate_ctxts menv cenv s cs (Rerr err) bv /\
((! i e'. c <> Chandle ()  i e') \/
 (! i. err <> Rraise (Int_error i))))
==>
evaluate_ctxts menv cenv s ((c,env) ::cs) (Rerr err) bv)

/\

(! menv cenv cs env s s' var res1 res2 i e'.
(
evaluate F menv cenv s (bind var (Litv (IntLit i)) env) e' (s', res1) /\
evaluate_ctxts menv cenv s' cs res1 res2)
==>
evaluate_ctxts menv cenv s ((Chandle ()  var e',env) ::cs) (Rerr (Rraise (Int_error i))) res2)`;

val _ = Hol_reln `

(! menv cenv env e c res bv s1 s2.
(
evaluate F menv cenv (0,s1) env e (s2, res) /\
evaluate_ctxts menv cenv s2 c res bv)
==>
evaluate_state (menv, cenv, s1, env, Exp e, c) bv)

/\

(! menv cenv s env v c bv.
(
evaluate_ctxts menv cenv (0,s) c (Rval v) bv)
==>
evaluate_state (menv, cenv, s, env, Val v, c) bv)`;
val _ = export_theory()

