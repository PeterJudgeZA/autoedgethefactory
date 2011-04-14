/** ------------------------------------------------------------------------
    File        : SecurityManager
    Purpose     : 
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Thu Mar 18 11:54:05 EDT 2010
    Notes       : 
  ---------------------------------------------------------------------- */
{routinelevel.i}

using OpenEdge.CommonInfrastructure.Common.IUserContext.
using OpenEdge.CommonInfrastructure.Common.UserContext.
using OpenEdge.CommonInfrastructure.Common.ISecurityManager.
using OpenEdge.CommonInfrastructure.Common.SecurityManager.
using OpenEdge.CommonInfrastructure.Common.AuthenticationError.
using OpenEdge.CommonInfrastructure.Common.IServiceManager.
using OpenEdge.CommonInfrastructure.Common.IComponentInfo. 
using OpenEdge.CommonInfrastructure.Common.ITenantManager.
using OpenEdge.CommonInfrastructure.Common.Service.

using OpenEdge.Core.Util.IObjectInput.
using OpenEdge.Core.Util.IObjectOutput.
using OpenEdge.Core.System.InvalidValueSpecifiedError.
using OpenEdge.Core.System.InvalidActionError.

using OpenEdge.Lang.Collections.IMap.
using OpenEdge.Lang.Collections.Map.
using OpenEdge.Lang.String.
using Progress.Lang.Class.

class OpenEdge.CommonInfrastructure.Server.SecurityManager abstract inherits SecurityManager 
        implements ISecurityManager:
    
    define protected property TenantManager as ITenantManager no-undo
        get():
            if not valid-object(TenantManager) then
                TenantManager = cast(ServiceManager:StartService(Class:GetClass('OpenEdge.CommonInfrastructure.Common.ITenantManager')), ITenantManager).
            
            return TenantManager.
        end get.
        set.

    constructor public SecurityManager(poServiceManager as IServiceManager, poComponentInfo as IComponentInfo):
        super(poServiceManager, poComponentInfo).
    end constructor.
    
    /** Validates that the passed context is valid and that the session can be established.
        
        @param IUserContext The passed-in user context. */
    method public override void ValidateSession(input poContext as IUserContext):
        define variable oStoredContext as IUserContext no-undo.
        
        /* do the validation, whatever that might entail */
        oStoredContext = RetrieveContextFromStore(poContext:ContextId).
        
        if not oStoredContext:Equals(poContext) then
            undo, throw new AuthenticationError(
                    'User context',
                    substitute('passed context does not match stored context (Contextx ID = &1)', poContext:ContextId)).
        
        CurrentUserContext = poContext.
    end method.
    
    /** Retrieves the context for a given ID from the context store. 
        
        @param longchar A context ID
        @return IUserContext The user context object associated with that ID */
    method protected IUserContext RetrieveContextFromStore (input pcContextId as longchar):
        define variable oUC as IUserContext no-undo.

        /* always read from "datastore" aka disk in our case */
        oUC =  ReadSerializedContext(pcContextId).
        
        if not valid-object(oUC) then
           undo, throw new InvalidValueSpecifiedError(
                            'user context',
                            substitute('context id &1', pcContextId)).
        return oUC.
    end method.
    
    method override public IUserContext ValidateSession(input pcContextId as longchar):
        
        ValidateSession(RetrieveContextFromStore(pcContextId)).
        
        /* HappyPlace! */
        return CurrentUserContext.
    end method.
        
    method override public void EndSession(input poContext as IUserContext):
        /* write out the context values */
        WriteSerializedContext(poContext).
    end method.
    
    method override public IUserContext GetUserContext(input pcContextId as longchar):
       return ValidateSession(pcContextId).
    end method.
    
    method abstract protected void ValidateCredentials(input pcUserName as character,
                                                       input pcUserDomain as character,
                                                       input pcPassword as character).
    
    method override public IUserContext UserLogin(input pcUserName as character,
                                                  input pcUserDomain as character,
                                                  input pcPassword as character):
        define variable oUC as IUserContext no-undo.
        
        /* validate login credentials */
        ValidateCredentials(pcUserName, pcUserDomain, pcPassword).
        
        /* create context and establish tenancy */
        oUC = CreateContextObject(pcUserName, pcUserDomain).         
        oUC:EstablishTenancy(TenantManager).
        
        WriteSerializedContext(oUC).
        ValidateSession(oUC).
        
        return oUC.
    end method.
    
    /** Creates a IUserContext object for a validated user/domain. Will usually be 
        overridden to add more details 
        
        @param character The user name
        @param character The user domain
        @return IUserContext The user's context object */
    method protected IUserContext CreateContextObject(input pcUserName as character,
                                                      input pcUserDomain as character):
        return new UserContext(pcUserName, pcUserDomain).                                                          
    end method.    
    
end class.