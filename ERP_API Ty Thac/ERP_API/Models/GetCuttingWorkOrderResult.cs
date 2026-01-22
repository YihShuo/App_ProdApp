namespace ERP_API.Models
{
    public class GetCycleCuttingWorkOrderResult
    {
        public string? Order { get; set; }

        public List<CycleList>? Items { get; set; }
    }

    public class CycleList
    {
        public string? Cycle { get; set; }

        public List<Part>? Part { get; set; }
    }

    public class Part
    {
        public string? ID { get; set; }

        public string? Name { get; set; }

        public List<SizeQty>? Size { get; set; }
    }

    public class GetPartCuttingWorkOrderResult
    {
        public string? Order { get; set; }

        public List<PartList>? Items { get; set; }
    }

    public class PartList
    {
        public string? ID { get; set; }

        public string? Name { get; set; }

        public List<Cycles>? Cycle { get; set; }
    }

    public class Cycles
    {
        public string? Cycle { get; set; }

        public List<SizeQty>? Size { get; set; }
    }

    public class SizeQty
    {
        public string? Size { get; set; }

        public int Qty { get; set; }
    }
}
