namespace ERP_API.Models
{
    public class OrderCycleList
    {
        public string? Order { get; set; }

        public List<CycleResult>? Cycles { get; set; }
    }

    public class CycleResult
    {
        public string? Cycle { get; set; }

        public int Dispatched { get; set; }

        public int Prepare { get; set; }
    }
}
