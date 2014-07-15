part of dnd.draggable;

/**
 * The [AvatarHandler] is responsible for creating, position, and removing 
 * a drag avatar. A drag avatar provides visual feedback during the drag 
 * operation.
 */
abstract class AvatarHandler {
  
  AvatarHandler() {
  }
  
  /**
   * Creates an [OriginalAvatarHandler].
   */
  factory AvatarHandler.original() {
    return new OriginalAvatarHandler();
  }
  
  /**
   * Creates a [CloneAvatarHandler].
   */
  factory AvatarHandler.clone() {
    return new CloneAvatarHandler();
  }
  
  /**
   * Called when the drag operation starts. 
   * 
   * A drag avatar is created and attached to the DOM.
   * 
   * The provided [draggable] is used to know where in the DOM the drag avatar
   * can be inserted.
   * 
   * The [mousePosition] is the position of the mouse relative to the whole 
   * document (page coordinates).
   */
  void dragStart(Element draggable, Point mousePosition);
  
  /**
   * Moves the drag avatar to the new [mousePosition]. 
   * 
   * [mousePositionStart] is the mouse position where the drag started and
   * [mousePosition] is the current mouse position. Both positions are 
   * relative to the whole document (page coordinates).
   */
  void drag(Point mousePositionStart, Point mousePosition);
  
  /**
   * Called when the drag operation ends. 
   * 
   * [mousePositionStart] is the mouse position where the drag started and
   * [mousePosition] is the current mouse position. Both positions are 
   * relative to the whole document (page coordinates).
   */
  void dragEnd(Point mousePositionStart, Point mousePosition);
  
  Point _lastTranslate;
  bool _updating = false;
  
  /**
   * Sets the CSS transform translate of [avatar]. Uses requestAnimationFrame
   * to speed up animation.
   */
  void setTranslate(Element avatar, Point position) {
    Function updateFunction = () {
      // Unsing `translate3d` to activate GPU hardware-acceleration (a bit of a hack).
      avatar.style.transform = 'translate3d(${position.x}px, ${position.y}px, 0)';
    };
    
    // Use request animation frame to update the transform translate.
    AnimationHelper.requestUpdate(updateFunction);            
  }
  
  /**
   * Removes the CSS transform of [avatar]. Also stops the requested animation
   * from [setTranslate].
   */
  void removeTranslate(Element avatar) {
    AnimationHelper.stop();
    avatar.style.transform = null;
  }
  
  /**
   * Sets the CSS left/top of [avatar].
   */
  void setLeftTop(Element avatar, Point position) {
    avatar.style.left = '${position.x}px';
    avatar.style.top = '${position.y}px';
  }
  
  /**
   * Helper method to get the offset of [element] relative to the document.
   */
  Point pageOffset(Element element) {
    Rectangle rect = element.getBoundingClientRect();
    return new Point(
        (rect.left + window.pageXOffset - document.documentElement.client.left).round(), 
        (rect.top + window.pageYOffset - document.documentElement.client.top).round());
  }
}


/**
 * The [OriginalAvatarHandler] uses the draggable element itself as drag 
 * avatar. It uses absolute or fixed positioning 
 */
class OriginalAvatarHandler extends AvatarHandler {
  
  /// The avatar element which is created in [dragStart].
  Element avatar;
  
  Point dragStartOffset;
  
  @override
  void dragStart(Element draggable, Point mousePosition) {
    // Use the draggable itself as avatar.
    avatar = draggable;
    
    // Calc the start offset of the mouse relative to the draggable.
    dragStartOffset = pageOffset(draggable);
    Point mouseOffset = mousePosition - dragStartOffset;
    
    // Ensure avatar has an absolute position.
    avatar.style.position = 'absolute';
    
    // Set the initial position.
    setLeftTop(avatar, mousePosition - mouseOffset);
  }
  
  @override
  void drag(Point mousePositionStart, Point mousePosition) {
    setTranslate(avatar, mousePosition - mousePositionStart);
  }
  
  /**
   * Called when the drag operation ends. 
   */
  @override
  void dragEnd(Point mousePositionStart, Point mousePosition) {
    // Remove the translate and set the new position as left/top.
    removeTranslate(avatar);
    setLeftTop(avatar, mousePosition - mousePositionStart + dragStartOffset);
  }
}


/**
 * [CloneAvatarHandler] creates a clone of the draggable element as drag avatar.
 * The avatar is removed at the end of the drag operation.
 */
class CloneAvatarHandler extends AvatarHandler {
  
  /// The avatar element which is created in [dragStart].
  Element avatar;
  
  @override
  void dragStart(Element draggable, Point mousePosition) {
    // Clone the draggable to create the avatar.
    avatar = (draggable.clone(true) as Element)
        ..attributes.remove('id')
        ..style.cursor = 'inherit';
    
    // Calc the position of the draggable.
    Point draggablePosition = pageOffset(draggable);
    
    // Set the initial position of avatar.
    setLeftTop(avatar, draggablePosition);
    
    // Ensure avatar has an absolute position.
    avatar.style.position = 'absolute';
    
    // Add the drag avatar to the parent element.
    draggable.parentNode.append(avatar);
  }
  
  @override
  void drag(Point mousePositionStart, Point mousePosition) {
    setTranslate(avatar, mousePosition - mousePositionStart);
  }
  
  /**
   * Called when the drag operation ends. 
   */
  @override
  void dragEnd(Point mousePositionStart, Point mousePosition) {
    avatar.remove();
  }
}


/**
 * Simple helper class to speed up animation with requestAnimationFrame.
 */
class AnimationHelper {
  
  static Function _lastUpdateFunction;
  static bool _updating = false;
  
  /**
   * Requests that the [updateFunction] be called. When the animation frame is
   * ready, the [updateFunction] is executed. Note that any subsequent calls 
   * in the same frame will overwrite the [updateFunction]. 
   */
  static void requestUpdate(void updateFunction()) {
    _lastUpdateFunction = updateFunction;
    
    if (!_updating) {
      window.animationFrame.then((_) => _update());
      _updating = true;
    }
  }
  
  /**
   * Stops the updating.
   */
  static void stop() {
    _updating = false;
  }
  
  static void _update() {
    // Test if it wasn't stopped.
    if (_updating) {
      _lastUpdateFunction();
      _updating = false;
    }
  }
}