# RE2NFA

## INTRODUZIONE

Un’espressione regolare rappresenta in maniera finita un linguaggio, ossia un insieme potenzialmente infinito di sequenze di *simboli* tratto da un alfabeto Sigma.

In generale, se `<re1>`, `<re2>` ... `<rek>` sono delle regexp, lo saranno anche

- `<re1>` `<re2>`...`<rek>`	*(sequenza)*
- `<re1>`| `<re2>`				*(or)*
- `<re1>*`							*(chiusura di Kleene)*
- `<re1>+`							*(ripetizione 1 o più volte)*

Ad ogni regexp corrisponde un automa a stati finiti non-deterministico *(o NFA)* in grado di determinare se una sequenza di “simboli” appartiene o no all’insieme definito dall’espressione regolare, in un tempo asintoticamente lineare rispetto alla lunghezza della stringa.

In particolare, in Prolog, le espressioni regolari saranno espresse come:

- `<re1>` `<re2>`...`<rek>` diventa `seq(re1, re2, ..., rek)`
- `<re1>`| `<re2>`	diventa `or(re1, re2, ..., rek)`
- `<re1>*` diventa `star(re1)`
- `<re1>+` diventa `plus(re1)`

L’alfabeto dei “simboli” Sigma è costituito da termini Prolog (più precisamente, da tutto ciò che soddisfa `compound/1` o `atomic/1`)

nfa.pl permette di trasformare delle espressioni regolari in automi a stati finiti non deterministici secondo l'algoritmo di Thompson.
E' composto da tre funzioni principali:

1. `is_regexp(RE)` che restituisce true ogni qual volta RE è una espressione regolare accettata dal linguaggio usato.
2. `nfa_regexp_comp(FA_Id, RE)` che compila la RE in un automa assegnandoli l'ID FA_Id.
3. `nfa_test(FA_Id, Input)` che simula l'esecuzione dell'automa e restituisce true nel caso Input sia completamente consumato dall'automa. 



## DESCRIZIONE PROGETTO

1. `IS_REGEXP/1`

   1.  `is_regexp(RE)`
      Per prima cosa si considerano i casi base in cui l'espressione è epsilon o un solo simbolo;
      In caso sia epsilon, il predicato risulta vero.
      In caso sia un simbolo, se è un atomo, il predicato risulta vero.
      Se non è un atomo, se non usa un funtore riservato, si controlla che sia accettato da `compound/1`.

      I casi ricorsivi sono dunque quelli in cui vengono usati i funtori riservati.
      Questi casi sono gestiti grazie all'utilizzo dell'operatore univ *(=..)* che divide l'espressione in una lista.

      I casi plus e star sono i più semplici:
      Basta controllare che la testa della lista ottenuta tramite univ sia plus (o star); a questo punto basta controllare che il secondo elemento della lista sia di fatto una regexp.

      Per quanto riguarda i casi or e seq, essi vengono gestiti attraverso la regola `is_reg_list/1`.

   2. `is_reg_list(RE)`
      Questa regola, nel caso base (un solo elemento), controlla semplicemente che l'elemento sia una regexp, nel caso la lista sia composta da più elementi, viene controllato ricorsivamente che tutti gli elementi siano regexp.
      E' presente anche un ulteriore caso di errore che stampa un messaggio in caso `RE` non sia una regexp e fa fallire la computazione usando il predicato `fail/0`.

   3. `is_symb(RE)`
      Questa regola viene usata quando `RE` non è un atomo;
      `is_symb/1` controlla che `RE` non utilizzi un funtore riservato usando univ e controllando che la testa della lista sia diversa da ognuno di questi e, in tal caso, controlla che `RE` sia un termine compound.


2. `NFA_REGEXP_COMP/2`

	1. `nfa_regexp_comp(FA_Id, RE)`
	   Come prima cosa viene definita la regola di arietà 2 che verrà usata dall'utente finale;
	   questa, come prima cosa, controlla che `FA_Id` non sia una variabile,
	   successivamente controlla che `RE` sia una regexp,
	   poi controlla che `FA_Id` sia unico tramite l'uso della regola `check_ID/1`.
	   Infine, crea gli stati iniziale e finale tramite il predicato `assert/1` utilizzando `gensym` per dare un nome agli stati e utilizza la regola `nfa_regexp_comp/4` che creerà il resto dell'automa.
	
2.  `check_ID(FA_Id)`
	   Controlla che `FA_Id` non sia già presente nella base di dati semplicemente verificando se esiste uno stato iniziale associato a quell'ID,
	   in tal caso stampa un messaggio di errore e fa fallire la computazione.
	
	1. `nfa_regexp_comp(FA_Id, RE, Initial, Final)`
   Questa regola gestisce i vari casi a seconda del tipo di `RE`;
	   Nel caso `RE` sia un solo simbolo, viene controllato che questo sia una regexp e in tal caso viene definita una delta dallo stato iniziale a quello finale che consuma tale simbolo.
	
	   Nel caso di una regexp del tipo `seq(RE1, RE2 ... REn)`
	   Viene generato l'automa usando la regola specifica `nfa_regexp_comp_seq/4` che prende in input una lista di espressioni regolari e per ognuna di esse crea le delta necessarie secondo l'algoritmo di Thompson.

	   La stessa cosa accade anche nel caso di una regexp del tipo `or(RE1, RE2 ... REn)` con la differenza che viene usata la regola specifica `nfa_regexp_comp_or/4`.
	   La necessità di due regole specifiche diverse nasce dalla applicazione dell'algoritmo di Thompson che è appunto diversa nei due casi e richiede diverse delta.
	
	   Nel caso di una regexp del tipo `star(RE)`
   vengono generati gli stati e le delta necessarie, sempre secondo l'algoritmo di Thompson.
	
	   Nel caso di una regexp del tipo `plus(RE)`
	   viene semplicemente richiamata la regola `nfa_regexp_comp/4` ponendo `RE = seq(RE, star(RE))`
	   In quanto `plus(RE)` è simile alla chiusura di Kleene, ma richiede almeno una ripetizione del suo argomento.

	   I vari casi vengono identificati sempre grazie all'utilizzo dell'operatore univ.


3. `NFA_TEST/2`

  1. `nfa_test(FA_Id, Input)`
     Anche in questo caso, viene definita prima la regola di arietà 2 che verrà usata dall'utente che controlla che esista un automa associato ad `FA_Id`, recuperandone lo stato iniziale e in tal caso utilizza la regola `nfa_test/3` con lo stato iniziale.

  2. `nfa_test(FA_Id, Input, State)`
     Questa è la regola che si occupa di verificare effettivamente se la stringa di input è accettata o meno controllando le delta associate ad `FA_Id` e a `State` (che è lo stato corrente) presenti nella base di dati.

     Il caso base di tale regola si incontra quando l'input è una lista vuota;
     in questo caso si controlla se si è in uno stato finale o meno (e dunque se l'input è accettato);
     se così non fosse, si controllano le epsilon-transizioni dallo stato corrente (se c'è ne sono).

     Nel caso ricorsivo invece viene consumata la testa della lista di input se si trova una delta che accetti tale simbolo associata ad `FA_Id` e a `State` e viene richiamata dunque la regola con la coda della lista e col nuovo stato `Next_State`.

     E' presente anche una definizione di tale regola che non consuma alcun simbolo ma controlla che siano possibili delle epsilon-transizioni dallo stato corrente e richiama dunque la regola con la testa e la coda della lista di input ma col nuovo stato.

     Infine, è presente un'ulteriore definizione di tale regola, usata nel caso `FA_Id` non sia un automa definito; questa non fa altro che segnalare l'errore all'utente.


4. `NFA_CLEAR/0` `NFA_CLEAR/1` e `NFA_LIST/0` `NFA_LIST/1`

	1. nfa_clear() nfa_clear(FA_Id)
	   Per permettere all'utente di svuotare la base di dati, viene implementata la regola `nfa_clear` che in caso di arietà 0 pulisce tutta la base di dati tramite il predicato `retractall/1` che viene chiamato rispettivamente con `nfa_initial`, `nfa_delta` ed `nfa_final` con tutte le rispettive
	   variabili impostate come don't care.
	
	   In caso di arietà 1 invece, viene fatta la stessa cosa, ma la prima variabile di `nfa_initial`, `nfa_delta` ed `nfa_final` viene impostata uguale al `FA_Id` con cui viene chiamato `nfa_clear/1`, in modo da eliminare gli stati e le delta relativi al solo automa identificato da `FA_Id`.

	2. `nfa_list()` `nfa_list(FA_Id)`
	   Regola che serve a mostrare all'utente il contenuto della base di dati.
	   Viene implementata nello stesso modo di `nfa_clear`, con la sola differenza che viene usato il predicato `listing/1` invece che `retractall/1`.

Sono inoltre presenti delle regole dynamic che informano l'interprete che la definizione dei predicati `nfa_initial`, `nfa_delta` ed `nfa_final` può cambiare durante l'esecuzione del programma.
Sono state introdotte per evitare un'eccezione nel caso l'utente richiami `nfa_list` senza prima aver definito alcun automa.
