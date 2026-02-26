// Mobile Menu Toggle
const mobileMenuToggle = document.querySelector(".mobile-menu-toggle");
const navMenu = document.querySelector(".nav-menu");

if (mobileMenuToggle) {
  mobileMenuToggle.addEventListener("click", () => {
    navMenu.classList.toggle("active");
    mobileMenuToggle.classList.toggle("active");
    // Toggle menu icon animation
    const spans = mobileMenuToggle.querySelectorAll("span");
    if (navMenu.classList.contains("active")) {
      spans[0].style.transform = "rotate(45deg) translate(5px, 5px)";
      spans[1].style.opacity = "0";
      spans[2].style.transform = "rotate(-45deg) translate(5px, -5px)";
    } else {
      spans[0].style.transform = "none";
      spans[1].style.opacity = "1";
      spans[2].style.transform = "none";
    }
  });

  // Close menu when clicking outside
  document.addEventListener("click", (e) => {
    if (!e.target.closest(".navbar")) {
      navMenu.classList.remove("active");
      mobileMenuToggle.classList.remove("active");
      const spans = mobileMenuToggle.querySelectorAll("span");
      spans[0].style.transform = "none";
      spans[1].style.opacity = "1";
      spans[2].style.transform = "none";
    }
  });

  // Close menu when clicking a link
  navMenu.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      navMenu.classList.remove("active");
      mobileMenuToggle.classList.remove("active");
      const spans = mobileMenuToggle.querySelectorAll("span");
      spans[0].style.transform = "none";
      spans[1].style.opacity = "1";
      spans[2].style.transform = "none";
    });
  });
}

// Smooth scroll with offset for fixed navbar
document.querySelectorAll('a[data-scroll]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    const href = this.getAttribute("href");
    if (href === "#") return;

    e.preventDefault();
    const target = document.querySelector(href);
    if (target) {
      const offset = 80; // navbar height
      const targetPosition = target.offsetTop - offset;

      window.scrollTo({
        top: targetPosition,
        behavior: "smooth",
      });
    }
  });
});

// Highlight active navigation link on scroll
const sections = document.querySelectorAll("section");
const navLinks = document.querySelectorAll("a[data-scroll]");

window.addEventListener("scroll", () => {
  const scrollPosition = window.pageYOffset + 80;

  sections.forEach((section) => {
    const sectionTop = section.offsetTop;
    const sectionHeight = section.offsetHeight;
    const sectionId = section.getAttribute("id");
    const link = document.querySelector(`a[data-scroll[href="#${sectionId}"]]`) || document.querySelector(`a[href="#${sectionId}"]`);

    if (link && scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
      navLinks.forEach((navLink) => navLink.classList.remove("active-link"));
      link.classList.add("active-link");
    }
  });
});

// Navbar background on scroll
const navbar = document.querySelector(".navbar");
let lastScroll = 0;

window.addEventListener("scroll", () => {
  const currentScroll = window.pageYOffset;

  if (currentScroll > 100) {
    navbar.classList.add("scrolled");
  } else {
    navbar.classList.remove("scrolled");
  }

  lastScroll = currentScroll;
});

// Intersection Observer for fade-in animations
const observerOptions = {
  threshold: 0.1,
  rootMargin: "0px 0px -50px 0px",
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("fade-in");
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

document.querySelectorAll(".feature-card, .download-card").forEach((card) => {
  observer.observe(card);
});

// Add fade-in class CSS dynamically if not already styled
if (!document.querySelector("#fade-in-style")) {
  const style = document.createElement("style");
  style.id = "fade-in-style";
  style.textContent = `
        .feature-card, .download-card {
            opacity: 0;
            transform: translateY(20px);
            transition: opacity 0.6s ease, transform 0.6s ease;
        }
        .feature-card.fade-in, .download-card.fade-in {
            opacity: 1;
            transform: translateY(0);
        }
    `;
  document.head.appendChild(style);
}

// Copy download link functionality
function copyToClipboard(text) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      showToast("Link copied to clipboard!");
    });
  }
}

// Simple toast notification
function showToast(message) {
  const existingToast = document.querySelector(".toast");
  if (existingToast) {
    existingToast.remove();
  }

  const toast = document.createElement("div");
  toast.className = "toast";
  toast.textContent = message;
  toast.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: #333;
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 9999;
        animation: slideInUp 0.3s ease;
    `;

  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = "slideOutDown 0.3s ease";
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Add slide animations
if (!document.querySelector("#slide-animations")) {
  const style = document.createElement("style");
  style.id = "slide-animations";
  style.textContent = `
        @keyframes slideInUp {
            from {
                transform: translateY(100px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        @keyframes slideOutDown {
            from {
                transform: translateY(0);
                opacity: 1;
            }
            to {
                transform: translateY(100px);
                opacity: 0;
            }
        }
    `;
  document.head.appendChild(style);
}

// Download button click tracking (for analytics)
document.querySelectorAll(".btn-download").forEach((button) => {
  button.addEventListener("click", function (e) {
    const platform =
      this.closest(".download-card").querySelector("h3").textContent;
    console.log(`Download clicked: ${platform}`);
    // Add your analytics tracking here
    // gtag('event', 'download', { platform: platform });
  });
});

// Stats counter animation
function animateCounter(element, target, duration = 2000) {
  const start = 0;
  const startTime = performance.now();

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);

    const current = Math.floor(progress * target);
    element.textContent = current.toLocaleString();

    if (progress < 1) {
      requestAnimationFrame(update);
    } else {
      element.textContent = target.toLocaleString() + "+";
    }
  }

  requestAnimationFrame(update);
}

// Trigger counter animation when stats are visible
const statsObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const statNumber = entry.target.querySelector(".stat-number");
        if (statNumber && !statNumber.classList.contains("animated")) {
          statNumber.classList.add("animated");
          const value = parseInt(statNumber.textContent.replace(/\D/g, ""));
          if (!isNaN(value)) {
            statNumber.textContent = "0";
            animateCounter(statNumber, value);
          }
        }
      }
    });
  },
  { threshold: 0.5 },
);

document.querySelectorAll(".stat").forEach((stat) => {
  statsObserver.observe(stat);
});

// Update copyright year
const currentYear = new Date().getFullYear();
document.querySelectorAll(".footer-bottom p").forEach((p) => {
  if (p.textContent.includes("©")) {
    p.textContent = p.textContent.replace(/\d{4}/, currentYear);
  }
});

// Prevent default on disabled buttons
document.querySelectorAll("button:disabled, .btn[disabled]").forEach((btn) => {
  btn.addEventListener("click", (e) => {
    e.preventDefault();
    showToast("This feature is coming soon!");
  });
});

console.log("🎓 Cardly Website Loaded Successfully!");
