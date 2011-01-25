/** ------------------------------------------------------------------------
    File        : as_startup.p
    Purpose     : AppServer startup procedure
     
    @param character A free-text string. This is assumed in our simple case
           to be the session code. If left blank, the session:client-type is
           used. 

    @author pjudge
    Created     : Fri Jun 04 13:54:27 EDT 2010
    Notes       :
  ----------------------------------------------------------------------*/
{routinelevel.i}

using OpenEdge.Core.System.ApplicationError.

using OpenEdge.Lang.ABLSession.
using OpenEdge.Lang.String.
using Progress.Lang.Class.
using Progress.Lang.AppError.
using Progress.Lang.Error.

/** -- params, defs -- **/
define input parameter pcStartupData as character no-undo.

run OpenEdge/CommonInfrastructure/start_session.p (pcStartupData).

ABLSession:Instance:SessionProperties:Put(new String('startup-procedure-parameters'), new String(pcStartupData)).

error-status:error = no.
return.

/** -- error handling -- **/
catch oException as ApplicationError:
    oException:LogError().

    message '*** OpenEdge.Core.System.ApplicationError'.
    message '~t' oException:ResolvedMessageText().
    
    return error oException:ResolvedMessageText().
end catch.

catch oAppError as Progress.Lang.AppError:
    message '*** Progress.Lang.AppError'.
    message '~t' oAppError:ReturnValue.
    message '~t' oAppError:CallStack.
    
    return error oAppError:ReturnValue.
end catch.

catch oError as Progress.Lang.Error:
    message '*** Progress.Lang.Error ' oError:GetMessageNum(1).
    message '~t' oError:GetMessage(1).
    message '~t' oError:CallStack.
    
    return error oError:GetMessage(1).
end catch.
/** -- eof -- **/