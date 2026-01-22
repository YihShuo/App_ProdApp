namespace ERP_API.Models
{
    public class LeanWorkOrder
    {
        public string? RY { get; set; }

        public string? BUY { get; set; }

        public string? SKU { get; set; }

        public string? PlanDate { get; set; }

        public int Pairs { get; set; }

        public int Input { get; set; }

        public int Output { get; set; }
    }

    public class OrderPartResult
    {
        public string? PartID { get; set; }

        public string? MaterialID { get; set; }

        public List<PartInfo>? PartName { get; set; }

        public int Dispatched { get; set; }
    }

    public class PartInfo
    {
        public string? ZH { get; set; }

        public string? EN { get; set; }

        public string? VI { get; set; }

        public string? Type { get; set; }

        public int Status { get; set; }
    }

    public class OrderSize
    {
        public string? Size { get; set; }

        public bool AllDispatched { get; set; }
    }

    public class OrderCycle
    {
        public string? Cycle { get; set; }

        public int Pairs { get; set; }

        public string? DispatchMachine { get; set; }

        public bool AllDispatched { get; set; }
    }

    public class OrderCycleResult
    {
        public string? Cycle { get; set; }

        public List<OrderCyclePart>? Parts { get; set; }
    }

    public class OrderCyclePart
    {
        public string? ID { get; set; }

        public string? Name { get; set; }

        public List<OrderCyclePartSize>? SizeQty { get; set; }
    }

    public class OrderCyclePartSize
    {
        public string? Size { get; set; }

        public int Qty { get; set; }

        public int Shortage { get; set; }

        public bool Dispatched { get; set; }
    }

    public class MachineResult
    {
        public string? Machine { get; set; }
    }

    public class ShippingPlan
    {
        public string? Date { get; set; }

        public List<ShippingContainer>? Estimate { get; set; }

        public List<ShippingContainer>? Actual { get; set; }
    }

    public class ShippingContainer
    {
        public int ID { get; set; }

        public string? Container { get; set; }

        public int Pairs { get; set; }

        public int Cartons { get; set; }

        public double CBM { get; set; }

        public List<ShippingContent>? Content { get; set; }
    }

    public class ShippingContent
    {
        public int Seq { get; set; }

        public string? Building { get; set; }

        public string? RY { get; set; }

        public string? PO { get; set; }

        public string? SKU { get; set; }

        public int Pairs { get; set; }

        public int Cartons { get; set; }

        public double CBM { get; set; }

        public string? Country { get; set; }

        public string? Status { get; set; }
    }

    public class BuyData
    {
        public string? BuyNo { get; set; }

        public int FinishedPairs { get; set; }

        public int Global { get; set; }

        public int SLT { get; set; }

        public int Vulcanize { get; set; }

        public int ColdVulcanize { get; set; }

        public int ColdCement { get; set; }

        public int NoCategory { get; set; }

        public List<BuyModel>? GlobalModels { get; set; }

        public List<BuyModel>? SLTModels { get; set; }
    }

    public class BuyModel
    {
        public int ID { get; set; }

        public string? Category { get; set; }

        public string? SubCategory { get; set; }

        public string? CuttingDie { get; set; }

        public string? Buildings { get; set; }

        public int Pairs { get; set; }

        public int FinishedPairs { get; set; }
    }

    public class BuySKU
    {
        public int ID { get; set; }

        public string? Name { get; set; }

        public string? Color { get; set; }

        public string? Last { get; set; }

        public string? SKU { get; set; }

        public string? SR { get; set; }

        public string? Buildings { get; set; }

        public int Pairs { get; set; }

        public int FinishedPairs { get; set; }
    }

    public class BuyRYs
    {
        public string? RY { get; set; }

        public string? ReceiveDate { get; set; }

        public string? ShippingDate { get; set; }

        public string? LaunchDate { get; set; }

        public string? LaunchLine { get; set; }

        public int Pairs { get; set; }

        public int FinishedPairs { get; set; }
    }

    public class BomPart
    {
        public string? PartID { get; set; }

        public string? PartName { get; set; }

        public string? SupID { get; set; }

        public string? SupName { get; set; }

        public string? MatID { get; set; }

        public string? MatName { get; set; }

        public double Usage { get; set; }

        public string? Unit { get; set; }

        public List<BomMaterial>? SubMaterials { get; set; }
    }

    public class BomMaterial
    {
        public string? SupID { get; set; }

        public string? SupName { get; set; }

        public string? MatID { get; set; }

        public string? MatName { get; set; }

        public double Usage { get; set; }

        public string? Unit { get; set; }

        public List<BomMaterial>? SubMaterials { get; set; }
    }

    public class ShipmentTrackingLean
    {
        public string? Building { get; set; }

        public string? Lean { get; set; }

        public List<ShipmentTrackingData>? Data { get; set; }
    }

    public class ShipmentTrackingData
    {
        public string? Type { get; set; }

        public string? ExFactoryDate { get; set; }

        public string? PlanDate { get; set; }

        public string? CuttingDie { get; set; }

        public string? SKU { get; set; }

        public string? BUY { get; set; }

        public string? RY { get; set; }

        public int Pairs { get; set; }

        public int CompletedPairs { get; set; }

        public string? ShipDate { get; set; }

        public string? Country { get; set; }
    }
}
