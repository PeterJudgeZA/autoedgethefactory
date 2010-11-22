/**------------------------------------------------------------------------
    File        : StandardBindingResolver
    Purpose     : 
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Tue Mar 09 09:02:30 EST 2010
    Notes       : 
  ---------------------------------------------------------------------- */
routine-level on error undo, throw.

using OpenEdge.Core.InjectABL.Lifecycle.StandardScopeEnum.
using OpenEdge.Core.InjectABL.Binding.IBindingResolver.
using OpenEdge.Core.InjectABL.Binding.IBinding.
using OpenEdge.Core.InjectABL.Binding.IBindingCollection.
using OpenEdge.Core.InjectABL.Binding.Conditions.ICondition.
using OpenEdge.Core.InjectABL.Binding.Conditions.Condition.
using OpenEdge.Lang.Collections.IIterator.
using OpenEdge.Lang.Collections.ObjectStack.
using Progress.Lang.Class.
using Progress.Lang.Object.

class OpenEdge.Core.InjectABL.Binding.StandardBindingResolver implements IBindingResolver:
    
    /** Returns valid binding(s) for a scope from a set of bindings */
    method public IBindingCollection Resolve(poBindings as IBindingCollection,
                                             poScopeCallback as class Class,
                                             poScope as StandardScopeEnum):
        define variable oResolvedBindings as IBindingCollection no-undo.
        define variable oIterator as IIterator no-undo.
        define variable oBinding as IBinding no-undo.
        
        oResolvedBindings = new IBindingCollection().
        
        oIterator = poBindings:Iterator().
        do while oIterator:HasNext():
            oBinding = cast(oIterator:Next(), IBinding).
            
            /* Scope needs to match */
            if not oBinding:ScopeCallbackType eq poScopeCallback or
               not oBinding:Scope eq poScope then
                next.
            
            /* All conditions need to be satisfied */
            if oBinding:IsConditional and
               not ResolveCondition(oBinding) then
                next.
            
            /* We can use this binding */
            oResolvedBindings:Add(oBinding).
        end.
        
        return oResolvedBindings.
    end method.
    
    method public IBindingCollection Resolve(input poBindings as IBindingCollection,
                                             input poService as class Class,
                                             input pcName as character):
        define variable oResolvedBindings as IBindingCollection no-undo.
        define variable oIterator as IIterator no-undo.
        define variable oBinding as IBinding no-undo.
        
        oResolvedBindings = new IBindingCollection().
        
        oIterator = poBindings:Iterator().
        do while oIterator:HasNext():
            oBinding = cast(oIterator:Next(), IBinding).
            
            /* Services need to match */
            if oBinding:Service ne poService then
                next.
            
            /* Names need to match */
            if oBinding:Name ne pcName then
                next.
            
            /* All conditions need to be satisfied */
            if oBinding:IsConditional and
               not ResolveCondition(oBinding) then
                next.
            
            /* We can use this binding */    
            oResolvedBindings:Add(oBinding).
        end.
        
        return oResolvedBindings.
    end method.
    
    method protected logical ResolveCondition(poBinding as IBinding):
        define variable oFIFOConditions as ObjectStack no-undo.
        define variable oCondition as ICondition no-undo.
        define variable lConditionsMet as logical no-undo.
        define variable lSubconditionMet as logical no-undo.
        define variable oLHS as ICondition no-undo.
        define variable oClauseOperator as ICondition no-undo.
        define variable oRHS as ICondition no-undo.
        define variable oOperator as ICondition no-undo.
        
        /* Extract the stack since we basically want to stack to be immutable, since we may
           use the binding again. Pop() will clear the stack. */
        oFIFOConditions = cast(poBinding:Condition:Clone(), ObjectStack).
        /* Invert the stack since we want to work backwards through the stack - FIFO rather than 
           LIFO - since the conditions are added 'forwards' and we want to read 'em that way. */
        oFIFOConditions:Invert().

        lConditionsMet = true.
        
        do while oFIFOConditions:Size gt 0:
            assign oCondition = cast(oFIFOConditions:Pop(), ICondition).
            
            case oCondition:
                /* 'When' starts a new set of evaluations. We treat this as an And (true);
                   this is necessary for cases where there is only one condition. */ 
                when Condition:When then
                    assign oOperator = Condition:And
                           lSubconditionMet = true.
                
                when Condition:And or 
                when Condition:Or then
                    oOperator = oCondition.
                
                otherwise
                    /* Clauses appear on the stack as Condition, Is/Not, Condition */
                    assign oLHS = oCondition
                           oClauseOperator = cast(oFIFOConditions:Pop(), ICondition) 
                           oRHS = cast(oFIFOConditions:Pop(), ICondition)
                           lSubconditionMet = EvaluateClause(oLHS, oClauseOperator, oRHS).
            end case.
            
            /* if need be, do the comparison */
            if valid-object(oOperator) then
            do:
                case oOperator:
                    when Condition:Or then
                    do:
                        lConditionsMet = lConditionsMet or lSubconditionMet.
                        
                        /* If we've satisfied at least one of the OR conditions,
                           we can leave this When block. Don't leave is the conditions
                           are false, since we may come across a true condition later. */
                        if lConditionsMet then
                            leave.
                    end.
                    
                    when Condition:And then
                    do:
                        lConditionsMet = lConditionsMet and lSubconditionMet.
                        
                        /* If we come across a single false condition, leave, since we know there
                           nothing more to do.  */
                        if not lConditionsMet then
                            leave.
                    end.
                end case.   /* operator */
            end.    /* valid operator */
        end.   /* stuff on stack */
        
        return lConditionsMet.
    end method.
    
    method protected logical EvaluateClause(poLHS as ICondition,
                                            poOperator as ICondition,
                                            poRHS as ICondition):
        
        define variable lConditionsMet as logical no-undo.
        
        case poOperator:
            when Condition:Is  then lConditionsMet = poLHS:Equals(poRHS). 
            when Condition:Not then lConditionsMet = not poLHS:Equals(poRHS).
        end case.
        
        return lConditionsMet.
    end method.

end class.