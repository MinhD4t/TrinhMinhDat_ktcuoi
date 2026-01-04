using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using TrinhMinhDat_ktcuoi.Models;

var builder = WebApplication.CreateBuilder(args);
var configuration = builder.Configuration;

// Controllers
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Swagger + JWT
builder.Services.AddSwaggerGen(c =>
{
c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
{
Name = "Authorization",
Type = SecuritySchemeType.ApiKey,
Scheme = "Bearer",
BearerFormat = "JWT",
In = ParameterLocation.Header,
Description = "Bearer {your JWT token}"
});

c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// CORS
builder.Services.AddCors(options =>
{
options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin()
          .AllowAnyMethod()
          .AllowAnyHeader());
});

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        configuration.GetConnectionString("DefaultConnection")));

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
options.Password.RequireDigit = true;
options.Password.RequiredLength = 6;
options.Password.RequireNonAlphanumeric = false;
options.Password.RequireUppercase = false;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// JWT
var jwt = configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwt["Key"]!);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
.AddJwtBearer(options =>
{
options.TokenValidationParameters = new TokenValidationParameters
{
ValidateIssuer = true,
ValidateAudience = true,
ValidateLifetime = true,
ValidateIssuerSigningKey = true,
ValidIssuer = jwt["Issuer"],
ValidAudience = jwt["Audience"],
IssuerSigningKey = new SymmetricSecurityKey(key)
};
});

builder.Services.AddAuthorization();

var app = builder.Build();


// =====================
// MIGRATE + SEED (SAFE)
// =====================
using (var scope = app.Services.CreateScope())
{
var services = scope.ServiceProvider;
var logger = services.GetRequiredService<ILogger<Program>>();

try
{
var db = services.GetRequiredService<AppDbContext>();
await db.Database.MigrateAsync();

var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

string[] roles = { "Admin", "Staff", "Customer", "User" };

foreach (var role in roles)
{
if (!await roleManager.RoleExistsAsync(role))
{
await roleManager.CreateAsync(new IdentityRole(role));
}
}

// Seed Admin
var adminEmail = "admin@demo.com";
var adminUser = await userManager.FindByEmailAsync(adminEmail);

if (adminUser == null)
{
adminUser = new ApplicationUser
{
UserName = "admin",
Email = adminEmail,
IsActive = true // 2. Thêm thuộc tính này cho Admin
};

var result = await userManager.CreateAsync(adminUser, "Admin123!");

if (result.Succeeded)
{
await userManager.AddToRoleAsync(adminUser, "Admin");
}
else
{
logger.LogError("Create admin failed: {Errors}",
    string.Join(", ", result.Errors.Select(e => e.Description)));
}
}
}
catch (Exception ex)
{
logger.LogError(ex, "Database error during seeding.");
}
}

// Middleware
if (app.Environment.IsDevelopment())
{
app.UseSwagger();
app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();


// =====================
// MODELS
// =====================

// 3. ĐÃ XÓA dòng: public class ApplicationUser : IdentityUser { } 
// Vì class này đã được định nghĩa trong Models/ApplicationUser.cs

public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Calendar> Calendars => Set<Calendar>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<Reminder> Reminders => Set<Reminder>();
    public DbSet<TwoFactorCode> TwoFactorCodes => Set<TwoFactorCode>();
}
public class Calendar
{
    public int Id { get; set; }
    public string Title { get; set; } = "";
    public bool IsHidden { get; set; }
}

public class Event
{
    public int Id { get; set; }
    public int CalendarId { get; set; }
    public Calendar? Calendar { get; set; }
    public string Title { get; set; } = "";
    public DateTime Start { get; set; }
    public DateTime End { get; set; }
    public bool IsHidden { get; set; }
}

public class Reminder
{
    public int Id { get; set; }
    public int EventId { get; set; }
    public Event? Event { get; set; }
    public DateTime RemindAt { get; set; }
    public string? Note { get; set; }
    public bool IsHidden { get; set; }
}

public class TwoFactorCode
{
    public int Id { get; set; }
    public string UserId { get; set; } = "";
    public string Code { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public bool Used { get; set; }
}
