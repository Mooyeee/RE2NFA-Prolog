%%%% Fagadau_Ionut_Daniel_845279
%%%% Messuri_Elettra_847008
%%%% De_Gennaro_Alessio_845031

%%%% -*- Mode: Prolog -*-
%%%% nfa.pl

%%% 1. IS_REGEXP

%%% Caso base: epsilon
is_regexp(epsilon).

%%% Caso base: un solo simbolo
is_regexp(RE) :-
    atomic(RE),
    !.

is_regexp(RE) :-
    is_symb(RE),
    !.

%%% Caso ricorsivo: star(Exp)
is_regexp(RE) :-
    RE =.. [star, REs],
    is_regexp(REs),
    !.

%%% Caso ricorsivo: plus(Exp)
is_regexp(RE) :-
    RE =.. [plus, REs],
    is_regexp(REs),
    !.

%%% Caso ricorsivo: seq(Exp)
is_regexp(RE) :-
    RE =.. [seq | REs],
    is_reg_list(REs),
    !.

%%% Caso ricorsivo, or(Exp)
is_regexp(RE) :-
    RE =.. [or | REs],
    is_reg_list(REs),
    !.

%%% Caso in cui RE non e' una regexp
is_regexp(RE) :-
    write('ERROR: '),
    write(RE),
    write(' is not a Regular Expression.\n'),
    fail.

%%% Gestione lista di REs
is_reg_list([RE]) :-
    is_regexp(RE).

is_reg_list([RE | REs]) :-
    is_regexp(RE),
    is_reg_list(REs).

is_symb(RE) :-
    RE =.. [Head | _],
    Head \= 'star',
    Head \= 'plus',
    Head \= 'or',
    Head \= 'seq',
    compound(RE).

%%% 2. NFA_REGEXP_COMP

%%% Caso base
nfa_regexp_comp(FA_Id, RE) :-
    nonvar(FA_Id),
    is_regexp(RE),
    !,
    check_ID(FA_Id),
    gensym(q, Initial),
    assert(nfa_initial(FA_Id, Initial)),
    gensym(q, Final),
    assert(nfa_final(FA_Id, Final)),
    nfa_regexp_comp(FA_Id, RE, Initial, Final).

%%% Controllo che l'ID sia unico
check_ID(FA_Id) :-
    nfa_initial(FA_Id, _),
    write('ERROR: there is already a Finite State Automata with this ID.\n'),
    !,
    fail.

check_ID(_) :-
    !.

%%% Linguaggio di una sola RE
nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    atomic(RE),
    assert(nfa_delta(FA_Id, Initial, RE, Final)),
    !.

nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    is_symb(RE),
    assert(nfa_delta(FA_Id, Initial, RE, Final)),
    !.

%%% Linguaggio seq(REs)
nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    RE =.. [seq | REs],
    nfa_regexp_comp_seq(FA_Id, REs, Initial, Final),
    !.

%%% Linguaggio or(REs)
nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    RE =.. [or | REs],
    nfa_regexp_comp_or(FA_Id, REs, Initial, Final),
    !.

%%% Linguaggio star(RE)
nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    RE =.. [star, REs],
    gensym(q, QI),
    assert(nfa_delta(FA_Id, Initial, epsilon, QI)),
    gensym(q, QF),
    assert(nfa_delta(FA_Id, QF, epsilon, Final)),
    assert(nfa_delta(FA_Id, QF, epsilon, QI)),
    assert(nfa_delta(FA_Id, Initial, epsilon, Final)),
    nfa_regexp_comp(FA_Id, REs, QI, QF),
    !.

%%% Linguaggio plus(RE)
nfa_regexp_comp(FA_Id, RE, Initial, Final) :-
    RE =.. [plus, REs],
    nfa_regexp_comp(FA_Id, seq(REs, star(REs)), Initial, Final),
    !.

%%% Gestione specifica caso seq(REs)
nfa_regexp_comp_seq(FA_Id, [RE], Initial, Final) :-
    nfa_regexp_comp(FA_Id, RE, Initial, Final),
    !.

nfa_regexp_comp_seq(FA_Id, [RE | REs], Initial, Final) :-
    gensym(q, F1),
    nfa_regexp_comp_seq(FA_Id, [RE], Initial, F1),
    gensym(q, I2),
    assert(nfa_delta(FA_Id, F1, epsilon, I2)),
    nfa_regexp_comp_seq(FA_Id, REs, I2, Final),
    !.

%%% Gestione specifica caso or(REs)
nfa_regexp_comp_or(FA_Id, [RE], Initial, Final) :-
    gensym(q, QI),
    assert(nfa_delta(FA_Id, Initial, epsilon, QI)),
    gensym(q, QF),
    assert(nfa_delta(FA_Id, QF, epsilon, Final)),
    nfa_regexp_comp(FA_Id, RE, QI, QF),
    !.

nfa_regexp_comp_or(FA_Id, [RE | REs], Initial, Final) :-
    nfa_regexp_comp_or(FA_Id, [RE], Initial, Final),
    nfa_regexp_comp_or(FA_Id, REs, Initial, Final).


%%% 3. NFA_TEST

%%% Chiamata principale arieta' 2
nfa_test(FA_Id, Input) :-
    nfa_initial(FA_Id, Initial),
    !,
    nfa_test(FA_Id, Input, Initial),
    !.

%%% Caso in cui FA_Id non sia definito
nfa_test(FA_Id, _) :-
    write('Error: '),
    write(FA_Id),
    write(' is not a Finite State Automata.'),
    fail,
    !.

%%% Caso base input vuoto
nfa_test(FA_Id, [], State) :-
    nfa_final(FA_Id, State).

nfa_test(FA_Id, [], State) :-
    nfa_delta(FA_Id, State, epsilon, Next_State),
    nfa_test(FA_Id, [], Next_State).

%%% Caso ricorsivo
nfa_test(FA_Id, [Input | Inputs], State) :-
    nfa_delta(FA_Id, State, epsilon, Next_State),
    nfa_test(FA_Id, [Input | Inputs], Next_State).

nfa_test(FA_Id, [Input | Inputs], State) :-
    nfa_delta(FA_Id, State, Input, Next_State),
    nfa_test(FA_Id, Inputs, Next_State).

%%% 4. NFA_CLEAR e NFA_LIST

%%% Svuota base di dati
nfa_clear() :-
    retractall(nfa_initial(_, _)),
    retractall(nfa_final(_, _)),
    retractall(nfa_delta(_, _, _, _)).

%%% Elimina solo l'automa FA_Id
nfa_clear(FA_Id) :-
    retractall(nfa_initial(FA_Id, _)),
    retractall(nfa_final(FA_Id, _)),
    retractall(nfa_delta(FA_Id, _, _, _)).

%%% Mostra tutta la base di dati
nfa_list() :-
    listing(nfa_initial(_, _)),
    listing(nfa_delta(_, _, _, _)),
    listing(nfa_final(_, _)).

%%% Mostra solo l'automa FA_Id
nfa_list(FA_Id) :-
    listing(nfa_initial(FA_Id, _)),
    listing(nfa_delta(FA_Id, _, _, _)),
    listing(nfa_final(FA_Id, _)).

%%% Informa l'interprete che i seguenti predicati
%%% potrebbero cambiare durante l'esecuzione
:- dynamic nfa_initial/2.
:- dynamic nfa_delta/4.
:- dynamic nfa_final/2.
