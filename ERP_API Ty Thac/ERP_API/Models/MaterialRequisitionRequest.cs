namespace ERP_API.Models
{
    public class MaterialRequisitionRequest
    {
        public string? Date { get; set; }

        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? RY_Begin { get; set; }

        public string? RY_End { get; set; }

        public string? Section { get; set; }
    }

    public class MRCardGenerateRequest
    {
        public string? ListNo { get; set; }

        public string? Section { get; set; }

        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? DemandDate { get; set; }

        public string? DemandTime { get; set; }

        public string? Source { get; set; }

        public string? Remark { get; set; }

        public string? RequestString { get; set; }

        public string? UserID { get; set; }

        public string? Factory { get; set; }
    }

    public class MRCardInfoRequest
    {
        public string? ListNo { get; set; }
    }

    public class WorkingDayRequest
    {
        public string? Date { get; set; }

        public string? Factory { get; set;}
    }
}
