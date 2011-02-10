/** ------------------------------------------------------------------------
    File        : QueryBlockTypeEnum
    Purpose     : numeration of the query block type (for, preselect)
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Tue Apr 07 12:21:09 EDT 2009
    Notes       : 
  ----------------------------------------------------------------------*/
{routinelevel.i}

using OpenEdge.Core.Util.IObjectOutput.
using OpenEdge.Core.Util.IObjectInput.
using OpenEdge.Lang.QueryBlockTypeEnum.
using OpenEdge.Lang.EnumMember.

class OpenEdge.Lang.QueryBlockTypeEnum final inherits EnumMember:
    
    define public static property Default   as QueryBlockTypeEnum no-undo get. private set.
    define public static property For       as QueryBlockTypeEnum no-undo get. private set.
    define public static property Preselect as QueryBlockTypeEnum no-undo get. private set.
    
    constructor static QueryBlockTypeEnum():
        QueryBlockTypeEnum:For = new QueryBlockTypeEnum('For').
        QueryBlockTypeEnum:Preselect = new QueryBlockTypeEnum('Preselect').
        
        /* Using Preselect instead of For since I'm assuming that these
           queries are going to be used for binding to a ProBindingSource,
           which prefers a preselect. */
        QueryBlockTypeEnum:Default = QueryBlockTypeEnum:Preselect.        
    end constructor.
    
    constructor public QueryBlockTypeEnum (input pcName as character):
        super (input pcName).
    end constructor.
    
    method static public QueryBlockTypeEnum EnumFromString(input pcName as character):
        define variable oEnum as QueryBlockTypeEnum no-undo.
        
        case pcName:
            when QueryBlockTypeEnum:For:ToString() then oEnum = QueryBlockTypeEnum:For. 
            when QueryBlockTypeEnum:Preselect:ToString() then oEnum = QueryBlockTypeEnum:Preselect.
        end case.
        
        return oEnum.
    end method. 
    
end class.