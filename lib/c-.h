generic<T>
struct Vec {
    T* data;
    int len;
};

generic<T>
T Vec_first(struct Vec<T>* self)
{
    return self->data[0];
}
