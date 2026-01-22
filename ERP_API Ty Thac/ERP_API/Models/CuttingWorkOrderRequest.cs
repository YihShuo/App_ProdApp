namespace ERP_API.Models
{
    public class CuttingWorkOrderRequest
    {
        public string? ListNo { get; set; }

        public string? Order { get; set; }

        public string? Section { get; set; }

        public string? UserID { get; set; }

        public string? Department { get; set; }

        public string? Machine { get; set; }

        public string? Factory { get; set; }

        public string? PartID { get; set; }

        public string? Type { get; set; }

        public string? ExecuteType { get; set; }
 
        public string? SelectedCycle { get; set; }

        public List<List<string>>? Cycle { get; set; }

        public string? SelectedSize { get; set; }

        public List<string>? Size { get; set; }

        public string? Date { get; set; }

        public int Pairs { get; set; }

        public int Shortage { set; get; }

        public string? Remark { get; set; }
    }
}
