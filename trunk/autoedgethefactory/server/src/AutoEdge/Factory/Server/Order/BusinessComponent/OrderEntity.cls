/** ------------------------------------------------------------------------
    File        : OrderEntity
    Purpose     : 
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Wed Dec 08 16:22:06 EST 2010
    Notes       : 
  ---------------------------------------------------------------------- */
routine-level on error undo, throw.

using OpenEdge.BusinessComponent.Entity.StandardBusinessEntity.

using OpenEdge.DataAccess.IDataAccess.

using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IServiceMessage.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IFetchResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ISaveRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ISaveResponse.
using OpenEdge.CommonInfrastructure.Common.IServiceManager.
using OpenEdge.CommonInfrastructure.Common.IComponentInfo.

using OpenEdge.Lang.RowStateEnum.

class AutoEdge.Factory.Server.Order.BusinessComponent.OrderEntity inherits StandardBusinessEntity:
    define temp-table eOrder no-undo
        field OrderNum      as integer
        field OrderId       as character
        field OrderDate     as date
        field EnteredDate   as datetime-tz
        field FromEmail     as logical

        field CustomerNum   as integer
        field CustomerName  as character
        field CustomerPO    as character
        
        field OrderAmount   as decimal
        field OrderStatus   as character
        field Instructions  as character
        
        field SalesrepCode  as character
        field DealerCode    as character
        
        index idx1 as primary unique Orderid
        index idx2 as unique OrderNum.

    /* one-to-one map to eOrder */
    define temp-table eOrderPayment no-undo
        field OrderNum          as integer
        field PromiseDate       as date
        field InvoiceNum        as character
        field ShipDate          as date
        field Terms             as character
        field ShippingAddressId as character
        field BillingAddressId  as character
        field Carrier           as character
        field Creditcard        as character
        
        index idx1 as primary unique OrderNum.
    
    @todo(task="refactor", action="merge OrderLine and FinishedItem into single BE table? ").
    define temp-table eOrderLine no-undo
        field OrderId           as character
        field LineNum           as integer
        field Price             as decimal
        field Quantity          as integer
        field Discount          as integer
        field ItemId            as character
        field OrderLineStatus   as character
        field FinishedItemId    as character
        index idx1 as primary unique OrderId LineNum.
    
    define temp-table eFinishedItem no-undo
        field FinishedItemId as character
        field ItemId as character
        field StatusDate as datetime-tz
        field FinishedItemStatus as character
        field ExternalId as character   /* This is likely to be the VIN */
        index idx1 as primary unique FinishedItemId.
    
    define temp-table eComponentItem no-undo
        field ItemId as character
        field FinishedItemId as character
        field Quantity as decimal
        index idx1 as primary unique FinishedItemId ItemId 
        index idx2 FinishedItemId
        .
    
    define temp-table eItem no-undo
        field ItemId as character
        field ItemNum as integer
        field ItemName as character
        field ItemType as character
        field Description as character
        field Price as decimal
        index idx1 as primary unique ItemId
        index idx2 as unique ItemNum
        .

    define private dataset dsOrder for eOrder, /*eOrderPayment,*/ eOrderLine, eFinishedItem, eItem, eComponentItem 
        data-relation for eOrder, eOrderLine relation-fields (OrderId, OrderId)
        data-relation for eOrderLine, eItem relation-fields (ItemId, ItemId)
        data-relation for eOrderLine, eFinishedItem relation-fields (FinishedItemId, FinishedItemId)
        data-relation for eFinishedItem, eComponentItem relation-fields (FinishedItemId, FinishedItemId)
        .
    
    constructor public OrderEntity(input poComponentInfo as IComponentInfo ):
        super (input poComponentInfo).
    end constructor.

    constructor public OrderEntity(input poComponentInfo as IComponentInfo, input poDAO as IDataAccess ):
        super(input poComponentInfo, input poDAO).
    end constructor.

    method override protected handle CopyStaticDataset (output dataset-handle phDataset):
        phDataset = dataset dsOrder:handle.
    end method.

	method override public ISaveResponse SaveData(input poRequest as ISaveRequest):
	    define variable hVehicle as handle no-undo.
	    define variable hFinishedItem as handle no-undo.
	    define variable hItem as handle no-undo.
	    define variable hDataset as handle no-undo.
	    define variable hQuery as handle no-undo.
	    define variable hOrder as handle no-undo.
	    
	    @todo(task="implement", action="").
	    cast(poRequest, IServiceMessage):GetMessageData(output hDataset).
	    hFinishedItem = hDataset:get-buffer-handle('eFinishedItem').
	    hOrder = hDataset:get-buffer-handle('eOrder').
	    
	    create query hQuery.
	    
        /* make sure new records have a salesrep */
	    hQuery:set-buffers(hOrder).
	    hQuery:query-prepare(substitute('for each &1 where row-state(&1) eq &2',
	                         hOrder:name,
	                         RowStateEnum:Created:Value)).
	    hQuery:query-open().
	    
	    hQuery:get-first().
	    do while hOrder:available:
            ValidateNewRow(hDataset, hOrder).
	        hQuery:get-next().
        end.
        hQuery:query-close().
        
        hQuery:set-buffers(hFinishedItem).
        hQuery:query-prepare(substitute('for each &1 ', hFinishedItem:name)).
        hQuery:query-open().
        
        hQuery:get-first().
        do while hFinishedItem:available:
            ValidateNewRow(hDataset, hFinishedItem).
            hQuery:get-next().
        end.
        
		return super:SaveData(input poRequest).	
        finally:
            hQuery:query-close().
            delete object hQuery.
        end finally.
	end method.
	
	method protected character GenerateVIN():
	    define variable cVIN as character no-undo.
	    /*
	    model, brand, year, etc 
	    */
	    cVIN = 'brand-model-year-000000'.
	    
	    return cVIN.
    end method.

	method override public IFetchResponse GetData( input pcMessageId as longchar ):
	    define variable oResponse as IFetchResponse no-undo.
		
		oResponse = super:GetData(input pcMessageId).
		
        /* Aggregate order total */
        
        return oResponse.        
	end method.

    method protected void ValidateNewRow(input phDataset as handle,
                                         input phBuffer as handle):
        case phBuffer:name:
            when 'eOrder' then
            do:
                if phBuffer::SalesrepCode eq '' then
                do:
                    /* find a salesrep from the dealer */
                end. 
            end.
            when 'eFinishedItem' then
            do:
                phBuffer::ExternalId = GenerateVIN().
            end.
        end case.
    end method.

end class.