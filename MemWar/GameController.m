#import "GameController.h"

/*
 * Ruby helper funciton prototypes
 */

VALUE new(char *);
VALUE call(VALUE reciever, char * methodName, int argc, ...);
void inspect(VALUE obj);
char*c_str(VALUE str);

@implementation GameController

- (id)initWithScene:(CoreScene *)aScene {
    if (self = [super init]) {
        scene = aScene;
    }
    return self;
}

- (void)initializeScene {
    [self initializeGame];
    
    VALUE mem = call(call(game, "core", 0), "mem", 0);
    
    for (int i = 0; i < 1024; i++) {
        VALUE instr = call(mem, "at", 1, INT2NUM(i));
        char *opcode = c_str((call(call(instr, "opcode", 0), "to_s", 0)));
        [scene setInstructionAt:i
                       toOpcode:opcode
                              l:NUM2INT(call(instr, "l", 0))
                              r:NUM2INT(call(instr, "r", 0))];
    }
//    scene.testLabel.text = @"Test String: Reloaded";
}

- (void)initializeGame {
    // Initialize the Ruby interpreter
    RUBY_INIT_STACK;
    ruby_init();
    ruby_init_loadpath();
    ruby_script("embed");
    
    // Load game.rb
    const char *bundlePath = [[[NSBundle mainBundle] bundlePath] fileSystemRepresentation];
    
    char *gameScriptPath = malloc(strlen(bundlePath)+28);
    snprintf(gameScriptPath, strlen(bundlePath)+28,
             "%s/Contents/Resources/game.rb", bundlePath);
    rb_require(gameScriptPath);
    
    // Get Game instance
    game = new("Game");
    
    // Load programs
    char *prog1Path = malloc(strlen(bundlePath)+29);
    char *prog2Path = malloc(strlen(bundlePath)+29);
    
    snprintf(prog1Path, strlen(bundlePath)+29,
             "%s/Contents/Resources/prog1.bc", bundlePath);
    snprintf(prog2Path, strlen(bundlePath)+29,
             "%s/Contents/Resources/prog2.bc", bundlePath);
    
    if (RTEST(call(game, "load_prog", 2, rb_str_new2(prog1Path), INT2NUM(0)))) {
        
    } else {
        @throw [NSException exceptionWithName:@"ProgramNotFoundException"
                            reason:[NSString
                                    stringWithFormat:@"%s did not load successfully",
                                    prog1Path]
                            userInfo:nil];
    }
    if (RTEST(call(game, "load_prog", 2, rb_str_new2(prog2Path), INT2NUM(512)))) {
        
    } else {
        @throw [NSException exceptionWithName:@"ProgramNotFoundException"
                                       reason:[NSString
                                               stringWithFormat:@"%s did not load successfully",
                                               prog2Path]
                                     userInfo:nil];
    }
}

- (void)cleanup {
    ruby_cleanup(0);
}

@end

/*
 * Ruby helper function definitions
 */

VALUE new(char *className) {
    return rb_class_new_instance(0, nil, rb_const_get(rb_cObject, rb_intern(className)));
}

VALUE call(VALUE reciever, char * methodName, int argc, ...) {
    va_list ar;
    VALUE *argv;
    
    if (argc > 0) {
        long i;
        
        va_start(ar, argc);
        
        argv = ALLOCA_N(VALUE, argc);
        
        for (i = 0; i < argc; i++) {
            argv[i] = va_arg(ar, VALUE);
        }
        va_end(ar);
    } else {
        argv = 0;
    }
    return rb_funcall2(reciever, rb_intern(methodName), argc, argv);
}

void inspect(VALUE obj) {
    puts(c_str(rb_inspect(obj)));
}

char *c_str(VALUE str) {
    if (RSTRING(str)->as.heap.ptr) {
        return RSTRING(str)->as.heap.ptr;
    } else {
        return RSTRING(str)->as.ary;
    }
}
