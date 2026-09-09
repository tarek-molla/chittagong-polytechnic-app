import io

path = r'cpi_app\lib\views\admin\teacher_management_view.dart'
with io.open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1) Add deactivation controller init in initState
old1 = """    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }"""

new1 = """    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
    _deactivationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _deactivationAnimation = CurvedAnimation(
      parent: _deactivationController,
      curve: Curves.easeInOut,
    );
    if (widget.teacher['is_active'] != true) {
      _deactivationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _InteractiveGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.teacher['is_active'] == true;
    final isActive = widget.teacher['is_active'] == true;
    if (wasActive && !isActive) {
      _deactivationController.forward(from: 0.0);
    } else if (!wasActive && isActive) {
      _deactivationController.reverse(from: 1.0);
    } else if (!isActive) {
      _deactivationController.value = 1.0;
    } else {
      _deactivationController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _deactivationController.dispose();
    super.dispose();
  }"""

if old1 not in content:
    print('OLD1 NOT FOUND')
else:
    content = content.replace(old1, new1)
    print('OLD1 REPLACED')

# 2) Wrap the card body in ColorFiltered + AnimatedOpacity for deactivated state
old2 = """    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container("""

new2 = """    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ColorFiltered(
          filter: ColorFilter.matrix(<double>[
            0.6, 0, 0, 0, 0,
            0, 0.6, 0, 0, 0,
            0, 0, 0.6, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.55,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Container("""

if old2 not in content:
    print('OLD2 NOT FOUND')
else:
    content = content.replace(old2, new2)
    print('OLD2 REPLACED')

# 3) Close the ColorFiltered/AnimatedOpacity wrappers before the closing ); of ScaleTransition
old3 = """          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {"""

new3 = """          ),
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {"""

if old3 not in content:
    print('OLD3 NOT FOUND')
else:
    content = content.replace(old3, new3)
    print('OLD3 REPLACED')

with io.open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('DONE')