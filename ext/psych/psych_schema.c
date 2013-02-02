#include <psych.h>

VALUE cPsychSchema;

/* call-seq: schema.build_exception(klass, message)
 *
 * Create an exception with class +klass+ and +message+
 */
static VALUE build_exception(VALUE self, VALUE klass, VALUE mesg)
{
    VALUE e = rb_obj_alloc(klass);

    rb_iv_set(e, "mesg", mesg);

    return e;
}

/* call-seq: schema.path2class(path)
 *
 * Convert +path+ string to a class
 */
static VALUE path2class(VALUE self, VALUE path)
{
#ifdef HAVE_RUBY_ENCODING_H
    return rb_path_to_class(path);
#else
    return rb_path2class(StringValuePtr(path));
#endif
}

void Init_psych_schema(void)
{
    VALUE psych  = rb_define_module("Psych");
    cPsychSchema = rb_define_class_under(psych, "Schema", rb_cObject);

    rb_define_private_method(cPsychSchema, "build_exception", build_exception, 2);
    rb_define_private_method(cPsychSchema, "path2class", path2class, 1);
}
/* vim: set noet sws=4 sw=4: */
