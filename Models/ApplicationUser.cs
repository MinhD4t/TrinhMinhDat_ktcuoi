using Microsoft.AspNetCore.Identity;

namespace TrinhMinhDat_ktcuoi.Models // Phải đúng namespace này
{
    public class ApplicationUser : IdentityUser
    {
        public bool IsActive { get; set; } = true;
    }
}