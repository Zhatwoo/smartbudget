"use client";

import { useEffect, useState } from "react";
import Image from "next/image";

export default function Home() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const scrollToSection = (id) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
      setMobileMenuOpen(false);
    }
  };

  const features = [
    {
      icon: "💰",
      title: "Smart Budget Planning",
      description: "Category-based budgets with real-time tracking and alerts to keep you on target.",
    },
    {
      icon: "📊",
      title: "Expense Tracking",
      description: "Track income and expenses with detailed categorization and transaction history.",
    },
    {
      icon: "📈",
      title: "Inflation Tracker",
      description: "Real-time inflation rates with historical data to adjust your budget accordingly.",
    },
    {
      icon: "💡",
      title: "Smart Suggestions",
      description: "Get intelligent financial recommendations based on your spending patterns.",
    },
    {
      icon: "📋",
      title: "Analytics & Reports",
      description: "Comprehensive spending analytics and insights to understand your finances better.",
    },
    {
      icon: "🔮",
      title: "Expense Predictions",
      description: "Future spending forecasts to help you plan ahead and avoid overspending.",
    },
    {
      icon: "🔔",
      title: "Bill Reminders",
      description: "Never miss a payment with smart notifications and upcoming bill tracking.",
    },
    {
      icon: "📱",
      title: "Visual Dashboards",
      description: "Interactive charts and graphs to visualize your financial health at a glance.",
    },
  ];

  const steps = [
    {
      number: "01",
      title: "Track",
      description: "Add your income and expenses with detailed categorization",
    },
    {
      number: "02",
      title: "Plan",
      description: "Set budgets for different categories and track your progress",
    },
    {
      number: "03",
      title: "Optimize",
      description: "Get smart suggestions and insights to improve your financial health",
    },
  ];

  const benefits = [
    "Real-time inflation tracking",
    "Smart financial insights",
    "Comprehensive analytics",
    "Bill reminders and notifications",
    "Multi-currency support",
    "Secure cloud sync",
  ];

  return (
    <div className="min-h-screen bg-white dark:bg-[#0a0a0a] text-gray-900 dark:text-gray-100">
      {/* Navigation Bar */}
      <nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          isScrolled
            ? "bg-white/80 dark:bg-[#0a0a0a]/80 backdrop-blur-lg border-b border-gray-200/50 dark:border-gray-800/50"
            : "bg-transparent"
        }`}
      >
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            <button
              onClick={() => scrollToSection("hero")}
              className="text-xl font-semibold text-gray-900 dark:text-white tracking-tight"
            >
              Smart Budget
            </button>
            <div className="hidden md:flex items-center space-x-10">
              <button
                onClick={() => scrollToSection("features")}
                className="text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                Features
              </button>
              <button
                onClick={() => scrollToSection("how-it-works")}
                className="text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                How It Works
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                Download
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="px-5 py-2.5 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg text-sm font-medium hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors"
              >
                Get Started
              </button>
            </div>
            <button
              className="md:hidden text-gray-900 dark:text-white"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                {mobileMenuOpen ? (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                ) : (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                )}
              </svg>
            </button>
          </div>
        </div>
        {mobileMenuOpen && (
          <div className="md:hidden bg-white dark:bg-[#0a0a0a] border-t border-gray-200 dark:border-gray-800">
            <div className="px-6 py-4 space-y-3">
              <button
                onClick={() => scrollToSection("features")}
                className="block w-full text-left py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                Features
              </button>
              <button
                onClick={() => scrollToSection("how-it-works")}
                className="block w-full text-left py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                How It Works
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="block w-full text-left py-2 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                Download
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="w-full px-5 py-2.5 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg text-sm font-medium"
              >
                Get Started
              </button>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section - Professional Split Layout */}
      <section
        id="hero"
        className="relative min-h-screen flex items-center overflow-hidden pt-20 bg-white dark:bg-[#0a0a0a]"
      >
        {/* Subtle Background Pattern */}
        <div className="absolute inset-0 bg-gradient-to-b from-gray-50/50 to-white dark:from-[#0a0a0a] dark:to-[#111111]"></div>
        
        <div className="relative z-10 max-w-7xl mx-auto px-6 lg:px-8 w-full py-20">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            {/* Left Side - Content */}
            <div className="space-y-10">
              <div className="inline-flex items-center gap-2.5 px-5 py-2.5 bg-blue-50 dark:bg-blue-950/30 border border-blue-100 dark:border-blue-900/50 rounded-lg text-sm font-medium text-blue-700 dark:text-blue-400">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
                <span>Your Personal Finance Assistant</span>
              </div>
              
              <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-gray-900 dark:text-white leading-[1.1] tracking-tight">
                Take Control of Your
                <span className="block mt-2 bg-gradient-to-r from-blue-600 via-blue-500 to-green-600 bg-clip-text text-transparent">
                  Finances
                </span>
              </h1>
              
              <p className="text-xl md:text-2xl text-gray-600 dark:text-gray-400 leading-relaxed max-w-xl font-light">
                Track expenses, plan budgets, and make smarter financial decisions with intelligent insights. Start your journey to financial freedom today.
              </p>
              
              <div className="flex flex-col sm:flex-row gap-4 pt-2">
                <a
                  href="/Smartbudget.apk"
                  download="Smartbudget.apk"
                  className="inline-flex items-center justify-center px-8 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-base hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg hover:shadow-xl"
                >
                  <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" />
                  </svg>
                  Download for Android
                </a>
                <button
                  onClick={() => scrollToSection("features")}
                  className="inline-flex items-center justify-center px-8 py-4 bg-white dark:bg-[#1a1a1a] text-gray-900 dark:text-white rounded-lg font-semibold text-base border border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-600 hover:bg-gray-50 dark:hover:bg-[#222222] transition-all duration-200"
                >
                  Learn More
                  <svg className="ml-2 w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>

              {/* Professional Stats */}
              <div className="flex gap-12 pt-8 border-t border-gray-200 dark:border-gray-800">
                <div>
                  <div className="text-4xl font-bold text-gray-900 dark:text-white mb-1">100%</div>
                  <div className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Secure</div>
                </div>
                <div>
                  <div className="text-4xl font-bold text-gray-900 dark:text-white mb-1">24/7</div>
                  <div className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Available</div>
                </div>
                <div>
                  <div className="text-4xl font-bold text-gray-900 dark:text-white mb-1">Free</div>
                  <div className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">To Start</div>
                </div>
              </div>
            </div>

            {/* Right Side - Professional App Preview */}
            <div className="relative hidden lg:block">
              <div className="relative">
                {/* Professional Phone Mockup */}
                <div className="relative mx-auto" style={{ width: '320px', aspectRatio: '9/16' }}>
                  {/* Phone Frame with Professional Shadow */}
                  <div className="absolute inset-0">
                    {/* Outer Glow */}
                    <div className="absolute -inset-4 bg-gradient-to-br from-blue-500/20 to-green-500/20 rounded-[3.5rem] blur-2xl"></div>
                    {/* Phone Body */}
                    <div className="absolute inset-0 bg-gradient-to-b from-gray-100 to-gray-200 dark:from-gray-800 dark:to-gray-900 rounded-[3rem] p-1.5 shadow-2xl">
                      {/* Screen Bezel */}
                      <div className="w-full h-full bg-gray-900 dark:bg-black rounded-[2.75rem] p-2">
                        {/* Screen */}
                        <div className="w-full h-full bg-white dark:bg-[#1a1a1a] rounded-[2.5rem] overflow-hidden relative">
                          <Image
                            src="/Dashboard.png"
                            alt="Smart Budget Dashboard"
                            fill
                            className="object-cover"
                            unoptimized
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Professional Floating Cards */}
                <div className="absolute -top-12 -right-12 bg-white dark:bg-[#1a1a1a] rounded-2xl p-5 shadow-2xl border border-gray-200/50 dark:border-gray-800/50 backdrop-blur-sm">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-lg">
                      <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div>
                      <div className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">Balance</div>
                      <div className="text-2xl font-bold text-gray-900 dark:text-white">₱28,000</div>
                    </div>
                  </div>
                </div>

                <div className="absolute -bottom-12 -left-12 bg-white dark:bg-[#1a1a1a] rounded-2xl p-5 shadow-2xl border border-gray-200/50 dark:border-gray-800/50 backdrop-blur-sm">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg">
                      <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                      </svg>
                    </div>
                    <div>
                      <div className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">This Month</div>
                      <div className="text-2xl font-bold text-gray-900 dark:text-white">₱27,000</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Professional Scroll Indicator */}
        <div className="absolute bottom-12 left-1/2 transform -translate-x-1/2 hidden lg:block">
          <button
            onClick={() => scrollToSection("features")}
            className="flex flex-col items-center gap-3 text-gray-400 dark:text-gray-600 hover:text-gray-600 dark:hover:text-gray-400 transition-colors group"
          >
            <span className="text-xs font-medium uppercase tracking-wider">Scroll</span>
            <div className="w-6 h-10 rounded-full border-2 border-gray-300 dark:border-gray-700 flex items-start justify-center p-2 group-hover:border-gray-400 dark:group-hover:border-gray-600 transition-colors">
              <div className="w-1.5 h-1.5 rounded-full bg-gray-400 dark:bg-gray-600 animate-bounce"></div>
            </div>
          </button>
        </div>
      </section>

      {/* Features Section */}
      <section
        id="features"
        className="py-24 md:py-32 bg-white dark:bg-[#0a0a0a]"
      >
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="text-center mb-20">
            <h2 className="text-4xl md:text-5xl font-bold mb-4 text-gray-900 dark:text-white tracking-tight">
              Powerful Features
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              Everything you need to manage your finances effectively
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <div
                key={index}
                className="group p-6 bg-gray-50 dark:bg-[#111111] rounded-xl border border-gray-200 dark:border-gray-800 hover:border-blue-300 dark:hover:border-blue-700 hover:shadow-lg transition-all duration-200"
              >
                <div className="text-4xl mb-4 transform group-hover:scale-110 transition-transform duration-200">
                  {feature.icon}
                </div>
                <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-white">
                  {feature.title}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section
        id="how-it-works"
        className="py-24 md:py-32 bg-gray-50 dark:bg-[#111111]"
      >
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="text-center mb-20">
            <h2 className="text-4xl md:text-5xl font-bold mb-4 text-gray-900 dark:text-white tracking-tight">
              How It Works
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              Get started in three simple steps
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            {steps.map((step, index) => (
              <div
                key={index}
                className="text-center relative"
              >
                {index < steps.length - 1 && (
                  <div className="hidden md:block absolute top-8 left-[60%] w-full h-0.5 bg-gradient-to-r from-blue-200 to-green-200 dark:from-blue-800 dark:to-green-800"></div>
                )}
                <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-gradient-to-br from-blue-500 to-green-500 text-white text-lg font-bold mb-6 shadow-lg">
                  {step.number}
                </div>
                <h3 className="text-2xl font-semibold mb-3 text-gray-900 dark:text-white">
                  {step.title}
                </h3>
                <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
                  {step.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Key Benefits Section */}
      <section className="py-24 md:py-32 bg-white dark:bg-[#0a0a0a]">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
            <div>
              <h2 className="text-4xl md:text-5xl font-bold mb-6 text-gray-900 dark:text-white tracking-tight">
                Why Choose Smart Budget?
              </h2>
              <p className="text-lg text-gray-600 dark:text-gray-400 mb-10 leading-relaxed">
                Experience the difference with our comprehensive financial management platform
              </p>
              <ul className="space-y-4">
                {benefits.map((benefit, index) => (
                  <li
                    key={index}
                    className="flex items-start text-base text-gray-700 dark:text-gray-300"
                  >
                    <span className="text-blue-600 dark:text-blue-400 mr-3 mt-1 text-xl">✓</span>
                    <span>{benefit}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl text-white shadow-xl">
                <div className="text-4xl font-bold mb-2">100%</div>
                <div className="text-sm opacity-90">Secure</div>
              </div>
              <div className="p-8 bg-gradient-to-br from-green-500 to-green-600 rounded-2xl text-white shadow-xl">
                <div className="text-4xl font-bold mb-2">24/7</div>
                <div className="text-sm opacity-90">Available</div>
              </div>
              <div className="p-8 bg-gradient-to-br from-purple-500 to-purple-600 rounded-2xl text-white shadow-xl">
                <div className="text-4xl font-bold mb-2">Smart</div>
                <div className="text-sm opacity-90">Insights</div>
              </div>
              <div className="p-8 bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl text-white shadow-xl">
                <div className="text-4xl font-bold mb-2">Free</div>
                <div className="text-sm opacity-90">To Start</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Screenshots/Preview Section */}
      <section className="py-24 md:py-32 bg-gray-50 dark:bg-[#111111]">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="text-center mb-20">
            <h2 className="text-4xl md:text-5xl font-bold mb-4 text-gray-900 dark:text-white tracking-tight">
              See It In Action
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              Beautiful, intuitive interface designed for your financial success
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              {
                src: "/Dashboard.png",
                title: "Dashboard",
                description: "Track your balance, income, and expenses at a glance",
              },
              {
                src: "/Profilesettings.png",
                title: "Profile & Settings",
                description: "Customize your preferences and manage your account",
              },
              {
                src: "/InflationTRacker.png",
                title: "Inflation Tracker",
                description: "Monitor inflation rates and adjust your budget accordingly",
              },
            ].map((screenshot, index) => (
              <div
                key={index}
                className="relative w-full rounded-2xl overflow-hidden group bg-white dark:bg-[#1a1a1a] border border-gray-200 dark:border-gray-800 shadow-lg hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-2"
                style={{ aspectRatio: '9/16' }}
              >
                <Image
                  src={screenshot.src}
                  alt={screenshot.title}
                  fill
                  className="object-cover"
                  unoptimized
                  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                />
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section
        id="download"
        className="py-24 md:py-32 bg-gradient-to-br from-gray-900 via-blue-900 to-green-900 dark:from-white dark:via-blue-50 dark:to-green-50 text-white dark:text-gray-900"
      >
        <div className="max-w-4xl mx-auto px-6 lg:px-8 text-center">
          <h2 className="text-4xl md:text-5xl font-bold mb-4 tracking-tight">
            Ready to Take Control?
          </h2>
          <p className="text-lg md:text-xl mb-12 opacity-90 dark:opacity-80 max-w-2xl mx-auto">
            Download Smart Budget today and start your journey to financial freedom
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <a
              href="/Smartbudget.apk"
              download="Smartbudget.apk"
              className="px-8 py-4 bg-white dark:bg-gray-900 text-gray-900 dark:text-white rounded-xl font-semibold text-base hover:bg-gray-100 dark:hover:bg-gray-800 transition-all duration-200 shadow-xl hover:shadow-2xl transform hover:-translate-y-1"
            >
              Download for Android
            </a>
            <a
              href="/Smartbudget-iOS-Simulator.zip"
              download="Smartbudget-iOS-Simulator.zip"
              className="px-8 py-4 bg-white dark:bg-gray-900 text-gray-900 dark:text-white rounded-xl font-semibold text-base hover:bg-gray-100 dark:hover:bg-gray-800 transition-all duration-200 shadow-xl hover:shadow-2xl transform hover:-translate-y-1"
            >
              Download for iOS (Simulator)
            </a>
          </div>
          <p className="text-sm mt-4 opacity-75 dark:opacity-60">
            iOS version is for Simulator use. For device installation, please use Xcode or TestFlight.
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-white dark:bg-[#0a0a0a] border-t border-gray-200 dark:border-gray-800 py-16">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
            <div>
              <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">Smart Budget</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Your personal finance assistant for smarter financial decisions.
              </p>
            </div>
            <div>
              <h4 className="text-sm font-semibold mb-4 text-gray-900 dark:text-white">Quick Links</h4>
              <ul className="space-y-3 text-sm text-gray-600 dark:text-gray-400">
                <li>
                  <button
                    onClick={() => scrollToSection("features")}
                    className="hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    Features
                  </button>
                </li>
                <li>
                  <button
                    onClick={() => scrollToSection("how-it-works")}
                    className="hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    How It Works
                  </button>
                </li>
                <li>
                  <button
                    onClick={() => scrollToSection("download")}
                    className="hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    Download
                  </button>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-semibold mb-4 text-gray-900 dark:text-white">Legal</h4>
              <ul className="space-y-3 text-sm text-gray-600 dark:text-gray-400">
                <li>
                  <a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">
                    Privacy Policy
                  </a>
                </li>
                <li>
                  <a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">
                    Terms of Service
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-semibold mb-4 text-gray-900 dark:text-white">Connect</h4>
              <div className="flex space-x-4">
                <a
                  href="#"
                  className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                  <span className="text-xl">📘</span>
                </a>
                <a
                  href="#"
                  className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                  <span className="text-xl">🐦</span>
                </a>
                <a
                  href="#"
                  className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                  <span className="text-xl">📷</span>
                </a>
              </div>
            </div>
          </div>
          <div className="border-t border-gray-200 dark:border-gray-800 pt-8 text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              &copy; {new Date().getFullYear()} Smart Budget. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
