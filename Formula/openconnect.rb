class Openconnect < Formula
  desc "Open client for Cisco AnyConnect VPN"
  homepage "https://www.infradead.org/openconnect/"
  url "ftp://ftp.infradead.org/pub/openconnect/openconnect-9.11.tar.gz"
  mirror "https://fossies.org/linux/privat/openconnect-9.11.tar.gz"
  sha256 "a3c63441395ebc073995a5f4713ab5599af63c04f7492b9b48df11a7fbcb06c7"
  license "LGPL-2.1-only"

  livecheck do
    url "https://www.infradead.org/openconnect/download.html"
    regex(/href=.*?openconnect[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_ventura:  "3df4b53a0b6d916b5cdca928b0d70a8f9d8d2b0704126aa0eea2a475e4261514"
    sha256 arm64_monterey: "93fae97cd8a542a3ef6efc22f448fde68dff891d280c2210f1da47aa16645adc"
    sha256 arm64_big_sur:  "c3d8358a28d9c25c3e79e9d9463ea0f8093029f5ae2431c2a2cf42329a698e6f"
    sha256 ventura:        "21ff1ee3c34373ddea492d1ae2d1fc3ac0c69eeffcb794fb2e8ba9009619a15a"
    sha256 monterey:       "db61b015f86a0d30c11279c5379c90db64844ae117a26aaa75e7c46d94426e36"
    sha256 big_sur:        "a6abb0db9058e11c23d7e3969b32ffc5613956a9183b0197b1c98b908ef38669"
    sha256 x86_64_linux:   "60bf232d6bfe8ad31bfa597fcf526037443ad8ee73c32b3e6647918e9d269d48"
  end

  head do
    url "git://git.infradead.org/users/dwmw2/openconnect.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "gnutls"
  depends_on "stoken"

  resource "vpnc-script" do
    url "https://gitlab.com/openconnect/vpnc-scripts/-/raw/473d3e810b8fe8223058ab580fac20c53204e677/vpnc-script"
    sha256 "4e0d4367806c8b54da76aaae4bb550993d8155894006705d21b16eabdbf47559"
  end

  def install
    (etc/"vpnc").install resource("vpnc-script")
    chmod 0755, etc/"vpnc/vpnc-script"

    if build.head?
      ENV["LIBTOOLIZE"] = "glibtoolize"
      system "./autogen.sh"
    end

    args = %W[
      --prefix=#{prefix}
      --sbindir=#{bin}
      --localstatedir=#{var}
      --with-vpnc-script=#{etc}/vpnc/vpnc-script
    ]

    system "./configure", *args

    # We pass noinst_PROGRAMS to avoid a failure with os-tcp-mtu, which is optional
    # Issue ref: https://gitlab.com/openconnect/openconnect/-/issues/612#note_1394913896
    system "make", "install", "noinst_PROGRAMS="
  end

  def caveats
    s = <<~EOS
      A `vpnc-script` has been installed at #{etc}/vpnc/vpnc-script.
    EOS

    s += if (etc/"vpnc/vpnc-script.default").exist?
      <<~EOS

        To avoid destroying any local changes you have made, a newer version of this script has
        been installed as `vpnc-script.default`.
      EOS
    end.to_s

    s
  end

  test do
    # We need to pipe an empty string to `openconnect` for this test to work.
    assert_match "POST https://localhost/", pipe_output("#{bin}/openconnect localhost 2>&1", "")
  end
end
